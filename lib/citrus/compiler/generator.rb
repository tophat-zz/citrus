module Citrus
  class Generator
    
    attr_reader :basic_block
    attr_reader :module
    attr_reader :builder
    attr_reader :locals
    attr_reader :parent
    
    def initialize(mod, function, parent=nil)
      @module = mod
      @locals = {}
      @parent = parent
      @function = function
      @basic_block = @function.basic_blocks.append
      @builder = LLVM::Builder.create
      @builder.position_at_end(@basic_block)
    end
    
    def array(values)
      ary = @builder.alloca(LLVM::Array(LLVM::Type(values.first), values.size))
      for index in 0...values.size
        ptr = @builder.gep(ary, [INT.from_i(0), INT.from_i(index)])
        @builder.store(values[index], ptr)
      end
      return ary
    end
    
    def string(value)
      ptr = GlobalStrings.pointer(value)
    end
    
    def float(value)
      FLOAT.from_f(value)
    end
    
    def number(value)
      INT.from_i(value)
    end
    
    def bool(value)
      BOOL.from_i(value ? 1 : 0)
    end
    
    def not(value)
      @builder.not(value)
    end
    
    def call(func, *args)
      begin
        GlobalFunctions.named(func).call(args, @builder)
      rescue NoMethodError # for C methods
        f = @module.functions.named(func)
        raise NoMethodError if f.nil?
        @builder.call(f, *args)
      end
    end
    
    def resolve_conflicts(*gens)
      locals = []
      gens.each{|g| locals += g.locals.keys}
      stat = locals.inject(Hash.new(0)){|h, e| h[e]+=1; h}
      stat.select{|k, v| v > 1}.collect{|a| a[0]}.each do |k|
        resolve_conflict(k, *gens)
      end
    end
    
    def resolve_conflict(name, *gens)
      ty = INT
      nodes = {}
      gens.select{|g| g.locals.has_key?(name)}.each do |g|
        bb = g.basic_block
        var = g.locals[name]
        builder = LLVM::Builder.create
        if bb == @builder.insert_block && !nodes.has_key?(bb.previous)
          builder.position_before(bb.previous.instructions.last)
          nodes[bb.previous] = var.value(builder)
        else
          builder.position_before(bb.instructions.last)
          nodes[bb] = var.value(builder)
        end
        builder.dispose
      end
      ptr = @builder.phi(ty, nodes)
      self.assign(name, ptr)
    end
    
    def assign(name, value)
      unless @locals.has_key?(name)
        @locals[name] = Variable.new(value, @builder) 
      else
        @locals[name].assign(value, @builder)
      end
    end
    
    def assign_global(name, value)
      unless GlobalVariables.named(name)
        GlobalVariables.add(name, value, @builder)
      else
        GlobalVariables.named(name).assign(value, @builder)
      end
    end
    
    def assign_index(name, index, value)
      ary = @locals[name].value(@builder)
      ptr = @builder.gep(ary, [INT.from_i(0), index])
      @builder.store(value, ptr)
    end
    
    def compare(op, lval, rval)
      case op.to_s
      when *CMP_MAPPING.keys
        if LLVM::Type(lval) == FLOAT.type || LLVM::Type(rval) == FLOAT.type
          symbol = "o#{CMP_MAPPING[op.to_s].to_s}".to_sym
          if LLVM::Type(lval) != FLOAT.type
            lval = @builder.ui2fp(lval, FLOAT.type)
          elsif LLVM::Type(rval) != FLOAT.type
            rval = @builder.ui2fp(rval, FLOAT.type)
          end
          @builder.fcmp(symbol, lval, rval)
        else
          symbol = CMP_MAPPING[op.to_s]
          symbol = "s#{symbol.to_s}".to_sym unless symbol == :eq || symbol == :ne
          @builder.icmp(symbol, lval, rval)
        end
      when "&&", "and"
        @builder.and(lval, rval)
      when "||", "or"
        @builder.or(lval, rval)
      end
    end
    
    def equate(op, lval, rval)
      if LLVM::Type(lval) == FLOAT.type || LLVM::Type(rval) == FLOAT.type
        symbol = "f#{EQU_MAPPING[op.to_s].to_s}".to_sym
        if LLVM::Type(lval) != FLOAT.type
          lval = @builder.ui2fp(lval, FLOAT.type)
        elsif LLVM::Type(rval) != FLOAT.type
          rval = @builder.ui2fp(rval, FLOAT.type)
        end
        @builder.send(symbol, lval, rval)
      else
        symbol = EQU_MAPPING[op.to_s]
        symbol = :sdiv if symbol == :div
        @builder.send(symbol, lval, rval)
      end
    end
    
    def vars
      return @parent.nil? ? @locals : @locals.merge(@parent.vars) 
    end
    
    def load(name)
      if @locals.has_key?(name)
        @locals[name].value(@builder)
      else
        self.vars[name].value(@builder)
      end
    end
    
    def load_global(name)
      GlobalVariables.named(name).value(@builder)
    end
    
    def load_index(ary, index)
      @builder.load(@builder.gep(ary, [INT.from_i(0), index]))
    end
    
    def function(name, args)
      GlobalFunctions.add(name, args) { |g| yield g }
    end
    
    def declare(name, args, ret, varargs = false)
      rtype = DEC_MAPPING[ret.to_sym]
      atypes = args.map{|arg| DEC_MAPPING[arg.to_sym]}
      @module.functions.add(name.to_s, LLVM::Type.function(atypes, rtype, :varargs => varargs))
    end
    
    def block
      Block.new(@module, @function, self) { |g| yield g if block_given? }
    end
    
    def condition(cond, thenblock, elseblock, elsifs=[])
      @basic_block = self.block.bb
      eb = elsifs.empty? ? elseblock : self.block
      efbs = []
      @builder.cond(cond, thenblock.bb, eb.bb)
      for i in 0...elsifs.length
        efbs += eb
        @builder.position_at_end(eb.bb)
        neb = i+1 == elsifs.length ? elseblock : self.block
        @builder.cond(elsifs[i][0], elsifs[i][1].bb, eb.bb)
        @builder.position_at_end(elsifs[i][1].bb)
        @builder.br(@basic_block)    
        eb = neb
      end
      @builder.position_at_end(thenblock.bb)
      @builder.br(@basic_block)
      @builder.position_at_end(elseblock.bb)
      @builder.br(@basic_block)
      @builder.position_at_end(@basic_block)
      self.resolve_conflicts(thenblock, elseblock, *efbs)
    end
    
    def case(val, cases, elseblock)
      ncases = {}
      for pair in cases
        ncases[pair[0].bb] = pair[1]
      end
      switch = @builder.switch(val, elseblock.bb, ncases)
      @basic_block = self.block.bb
      @builder.position_at_end(elseblock.bb)
      @builder.br(@basic_block)
      ncases.each_value do |c|
        @builder.position_at_end(c[1])
        @builder.br(@basic_block)
      end
      @builder.position_at_end(@basic_block)
      self.resolve_conflicts(elseblock, *cases.keys)
    end
    
    def begin(rblock, elblock, enblock)
      cond = self.compare(:==, self.load_global(STS_GLOBAL), self.number(1))
      @builder.cond(cond, rblock.bb, elblock.bb)
      @basic_block = self.block.bb
      @builder.position_before(rblock.bb.instructions.first)
      self.assign_global(STS_GLOBAL, self.number(0))
      @builder.position_at_end(rblock.bb)
      @builder.br(enblock.bb)
      @builder.position_at_end(elblock.bb)
      @builder.br(enblock.bb)
      @builder.position_before(enblock.bb.instructions.first)
      self.resolve_conflicts(rblock, elblock)
      @builder.position_at_end(enblock.bb)
      @builder.br(@basic_block)
      @builder.position_at_end(@basic_block)
      @locals.merge!(enblock.locals)
    end
    
    def unwind
      @builder.unwind
    end
    
    # Needs to be called before running any loop command
    # (specifically before calculating the conditions for the loop)
    def preploop(looptype=nil, *args)
      if looptype == :for
        self.assign("for", INT.from_i(0))
        self.assign(args[0], self.load_index(args[1], self.number(0)))
      end
      @basic_block = self.block.bb
      @builder.br(@basic_block)
      @builder.position_at_end(@basic_block)
    end
    
    def while(cond)
      @builder.position_before(@basic_block.instructions.first)
      generator = Generator.new(@module, @function, self)
      yield generator
      generator.break(@basic_block)
      generator.finish
      self.resolve_conflicts(generator, self)
      @builder.position_at_end(@basic_block)
      @basic_block = self.block.bb
      @builder.cond(cond, generator.basic_block, @basic_block)
      @builder.position_at_end(@basic_block)
    end
    
    def for(var, indices)
      generator = Generator.new(@module, @function, self)
      generator.assign(var, generator.load_index(indices, generator.load("for")))
      yield generator
      generator.assign("for", generator.equate(:+, generator.load("for"), generator.number(1)))
      generator.break(@basic_block)
      generator.finish
      @builder.position_at_end(@basic_block)
      self.resolve_conflict("for", generator, self)
      @basic_block = self.block.bb
      size = LLVM::C.LLVMGetArrayLength(LLVM::Type(indices).element_type)
      cond = self.compare(:<, self.load("for"), self.number(size))
      @builder.cond(cond, generator.basic_block, @basic_block)
      @builder.position_at_end(@basic_block)
    end
    
    def return(value=self.number(0))
      unless @finished
        @function.return(value, @builder)
        @finished = true
      end
    end
    
    def break(block)
      unless @finished
        @builder.br(block)
      end
    end
    
    def finish
      @builder.dispose
    end

  end
end