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
      @locals = parent.locals.clone unless parent.nil?
      @basic_block = @function.basic_blocks.append
      @builder = LLVM::Builder.create
      @builder.position_at_end(@basic_block)
    end
    
    def array(values)
      return Array.create(values, @builder)
    end
    
    def range(first, last, full)
      ary = @builder.alloca(LLVM::Array(Object.type, 0))
      iteration = @builder.alloca(Object.type)
      @builder.store(first.pointer, iteration)
      index = @builder.alloca(Object.type)
      @builder.store(self.number(0).pointer, index)
      li = last.to_i(self)
      self.preploop(:while)
      self.while(self.compare(full ? :<= : :<, Object.new(@builder.load(iteration)), li)) do |gw|
        ival = Object.new(gw.builder.load(index))
        val = Object.new(gw.builder.load(iteration))
        ptr = gw.builder.gep(ary, [INT.from_i(0), ival.to_i(gw)])
        gw.builder.store(val.pointer, ptr)
        gw.builder.store(gw.equate(:+, val, gw.number(1)).pointer, iteration)
        gw.builder.store(gw.equate(:+, ival, gw.number(1)).pointer, index)
      end
      ival = Object.new(@builder.load(index))
      return Array.new(ary, ival) 
    end
    
    def string(value)
      Object.create(GlobalStrings.pointer(value), @builder)
    end
    
    def float(value)
      Object.create(FLOAT.from_f(value), @builder)
    end
    
    def number(value)
      Object.create(INT.from_i(value), @builder)
    end
    
    def bool(value)
      Object.create(BOOL.from_i(value ? 1 : 0), @builder)
    end
    
    def negate(value)
      Object.create(@builder.neg(value.to_i(self)), @builder)
    end
    
    def not(value)
      Object.create(@builder.not(value.to_b(self)), @builder)
    end
    
    def call(func, *args)
      GlobalFunctions.named(func).call(args, self)
    end
    
    def resolve_conflicts(*gens)
      locals = []
      gens.each{|g| locals += g.locals.keys}
      stat = locals.inject(Hash.new(0)){|h, e| h[e]+=1; h}
      stat.select{|k, v| v > 1}.collect{|a| a[0]}.each do |k|
        resolve_conflict(k, *gens) unless @locals.has_key?(k)
      end
    end
    
    def resolve_conflict(name, *gens)
      ty = Object.type
      nodes = {}
      gens.select{|g| g.locals.has_key?(name)}.each do |g|
        bb = g.basic_block
        var = g.locals[name]
        builder = LLVM::Builder.create
        if bb == @builder.insert_block && !nodes.has_key?(bb.previous)
          builder.position_before(bb.previous.instructions.last)
          nodes[bb.previous] = var.value(builder).pointer
        else
          builder.position_before(bb.instructions.last)
          nodes[bb] = var.value(builder).pointer
        end
        builder.dispose
      end
      ptr = @builder.phi(ty, nodes)
      self.assign(name, Object.new(ptr, @builder))
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
      ary = self.load(name)
      length = @builder.alloca(INT)
      @builder.store(ary.length, length)
      tb = self.block do |gb|
        gb.builder.store(gb.equate(:+, index, gb.number(1)), length)
      end
      cond = gb.compare(:<=, ary.length, index)
      self.condition(cond, tb.bb, self.block.bb)
      ary.length = @builder.load(length)
      ptr = @builder.gep(ary.pointer, [INT.from_i(0), index])
      @builder.store(value, ptr)
    end
    
    def compare(op, lval, rval)
      case op.to_s
      when *CMP_MAPPING.keys
        #meth_name = Citrus.const_get(CMP_MAPPING[op.to_s].to_s.upcase.to_sym)
        #return Object.new(@builder.call(@module.functions.named(meth_name), lval.pointer, rval.pointer))
        pointer = @builder.alloca(Object.type)
        symbol = CMP_MAPPING[op.to_s]
        symbol = "s#{symbol.to_s}".to_sym unless symbol == :eq || symbol == :ne
        struct = Object.create(@builder.icmp(symbol, lval.to_i(self), rval.is_a?(Object) ? rval.to_i(self) : rval), @builder)
        @builder.store(struct.pointer, pointer)
        return Object.new(@builder.load(pointer))
      when "&&", "and"
        Object.create(@builder.and(lval.to_b(self), rval.to_b(self)), @builder)
      when "||", "or"
        Object.create(@builder.or(lval.to_b(self), rval.to_b(self)), @builder)
      end
    end
    
    def equate(op, lval, rval)
      #meth_name = Citrus.const_get(EQU_MAPPING[op.to_s].to_s.upcase.to_sym)
      #return Object.new(@builder.call(@module.functions.named(meth_name), lval.pointer, rval.pointer))
      pointer = @builder.alloca(Object.type)
      symbol = EQU_MAPPING[op.to_s]
      symbol = :sdiv if symbol == :div
      struct = Object.create(@builder.send(symbol, lval.to_i(self), rval.to_i(self)), @builder)
      @builder.store(struct.pointer, pointer)
      return Object.new(@builder.load(pointer))
    end
    
    def load(name)
      @locals[name].value(@builder)
    end
    
    def load_global(name)
      GlobalVariables.named(name).value(@builder)
    end
    
    def load_index(ary, index)
      Object.new(@builder.load(@builder.gep(ary.pointer, [INT.from_i(0), index.to_i(self)])))
    end
    
    def function(name, args)
      return GlobalFunctions.add(name, args) { |g| yield g }
    end
    
    def declare(name, args, ret)
      return GlobalFunctions.declare(name, args, ret)
    end
    
    def block
      return Block.new(@module, @function, self) { |g| yield g if block_given? }
    end
    
    def condition(cond, thenblock, elseblock, elsifs=[])
      efbs = []
      @basic_block = self.block.bb
      eb = elsifs.empty? ? elseblock : self.block
      @builder.cond(cond.to_b(self), thenblock.bb, eb.bb)
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
        ncases[pair[0]] = pair[1].bb
      end
      switch = @builder.switch(val, elseblock.bb, ncases)
      @basic_block = self.block.bb
      @builder.position_at_end(elseblock.bb)
      @builder.br(@basic_block)
      ncases.each_value do |bb|
        @builder.position_at_end(bb)
        @builder.br(@basic_block)
      end
      @builder.position_at_end(@basic_block)
      self.resolve_conflicts(elseblock, *cases.values)
    end
    
    def begin(rblock, elblock, enblock)
      cond = self.compare(:==, self.load_global(STS_GLOBAL), self.number(1))
      @builder.cond(cond.to_b(self), rblock.bb, elblock.bb)
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
        self.assign("for", self.number(0))
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
      @builder.cond(cond.to_b(self), generator.basic_block, @basic_block)
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
      cond = self.compare(:<, self.load("for"), indices.length(@builder))
      @builder.cond(cond.to_b(self), generator.basic_block, @basic_block)
      @builder.position_at_end(@basic_block)
    end
    
    def return(value=nil)
      unless @finished
        value ||= self.number(0)
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