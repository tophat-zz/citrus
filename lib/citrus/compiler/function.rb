module Citrus
  class Function
    
    attr_reader :varargs
    attr_reader :generator
    
    def initialize(name, args, mod)
      @name = name
      @module = mod
      @rtype = LLVM::Type.opaque
      @atypes = args.map{LLVM::Type.opaque}
      @args = args.map{|arg| arg.class.to_s == "String" ? arg.to_a : arg}
      @varargs = @args.empty? ? false : (@args.last[0].slice(0, 1) == "*")
      @func = @module.functions.add(name, LLVM::Type.function(@atypes, @rtype, :varargs => @vaargs))
      build_function { |g| yield g if block_given? }
    end
    
    def args
      return @args.map{|arg| arg[0]}
    end
    
    def return(value, builder)
      @rtype.refine(LLVM::Type(value)) if @rtype.kind == :opaque
      builder.ret(value)
    end
    
    def call(args, builder)
      for i in 0...@atypes.size
        @atypes[i].refine(LLVM::Type(args[i])) if @atypes[i].kind == :opaque
      end
      builder.call(@func, *args)
    end
    
    def force_types(args, ret=nil)
      unless args.empty?
        for i in 0...@atypes.size
          @atypes[i].refine(LLVM::Type(args[i])) if @atypes[i].kind == :opaque
        end
      end
      unless ret.nil?
        @rtype.refine(ret) if @rtype.kind == :opaque
      end
    end
    
    def method_missing(symbol, *args, &block)
      @func.send(symbol, *args, &block)
    end
    
    private
    
    def build_function
      @generator = Generator.new(@module, self)
      @args.each do |arg|
        @generator.assign(arg[0], @func.params[@args.index(arg)])
      end
      yield generator
      @generator.return
      @generator.finish
    end
  
  end
  
  class GlobalFunctions
  
    def self.init(mod)
      @module ||= mod
      @functions ||= {}
    end
  
    def self.add(name, args)
      return @functions[name] = Function.new(name, args, @module) { |g| yield g if block_given? }
    end
    
    def self.named(name)
      return @functions[name]
    end
  
  end
end