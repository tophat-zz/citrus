module Citrus
  class Function
    
    attr_reader :varargs
    attr_reader :generator
    
    def initialize(name, args, mod)
      @name = "ct.#{name}"
      @module = mod
      @rtype = Object.type
      @atypes = args.map{Object.type}
      @args = args.map{|arg| arg.class.to_s == "String" ? arg.to_a : arg}
      @varargs = @args.empty? ? false : (@args.last[0].slice(0, 1) == "*")
      if @varargs
        @args.last[0] = @args.last[0].slice(1,  @args.last[0].length)
        @atypes.pop
      end
      @func = @module.functions.add(@name, LLVM::Type.function(@atypes, @rtype, :varargs => @varargs))
      build_function { |g| yield g if block_given? }
    end
    
    def pointer
      return @func
    end
    
    def args
      return @args.map{|arg| arg[0]}
    end
    
    def return(value, builder)
      builder.ret(value.pointer)
    end
    
    def call(args, generator)
      Object.new(generator.builder.call(@func, *args.collect{|arg| arg.pointer}), generator.builder)
    end
    
    def finish
      @generator.return
      @generator.finish
    end
    
    def method_missing(symbol, *args, &block)
      @func.send(symbol, *args, &block)
    end
    
    private
    
    def build_function
      @generator = Generator.new(@module, self)
      @args.each do |arg|
        if arg == @args.last && @varargs
        #  @generator.assign(arg[0], Object.from_va(@generator.builder))
        else
          @generator.assign(arg[0], Object.new(@func.params[@args.index(arg)], @generator.builder))
        end
      end
      yield generator
    end
  
  end
 
  class ExternFunction 
    
    def initialize(name, args, ret, mod)
      @name = name.to_s
      @module = mod
      @rtype = DEC_MAPPING[ret.to_sym]
      @atypes = args.map{|arg| DEC_MAPPING[arg.to_sym]}
      @func = @module.functions.add(name.to_s, LLVM::Type.function(@atypes, @rtype))
    end
    
    def pointer
      return @func
    end
    
    def return_type
      return @rtype
    end
    
    def arg_types
      return @atypes
    end
    
    def call(args, generator)
      primitives = args.collect do |arg|
        type = @atypes[args.index(arg)]
        arg.primitive(type, generator)
      end
      Object.create(generator.builder.call(@func, *primitives), generator.builder)
    end
    
  end

  class GlobalFunctions
  
    def self.init(mod)
      @module ||= mod
      @functions ||= {}
    end
  
    def self.add(name, args)
      generator = nil
      @functions[name] = Function.new(name, args, @module) { |g| generator =  g }
      yield generator if block_given?
      @functions[name].finish
      return @functions[name]
    end
    
    def self.declare(name, args, ret)
      return @functions[name.to_s] = ExternFunction.new(name, args, ret, @module)
    end
    
    def self.named(name)
      return @functions[name]
    end
  
  end       
end