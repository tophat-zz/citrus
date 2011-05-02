module Citrus
  class Variable
    
    attr_reader :type
    attr_reader :pointer
    
    def initialize(value, builder)
      @type = LLVM::Type(value)
      @pointer = builder.alloca(@type)
      builder.store(value, @pointer)
    end
    
    def assign(value, builder)
      type = LLVM::Type(value)
      unless type == @type
        @type = type
        @pointer = builder.alloca(type)
      end
      builder.store(value, @pointer)
    end
    
    def value(builder)
      builder.load(@pointer)
    end
  
  end
  
  class GlobalVariable < Variable
    
    def initialize(name, value, mod, builder)
      @name = name
      @module = mod
      @type = LLVM::Type(value)
      @pointer = @module.globals.add(@type, @name)
      @pointer.initializer = value
    end
    
    def assign(value, builder)
      @type = LLVM::Type(value)
      builder.store(value, @pointer)
    end
    
    def value(builder)
      builder.load(@module.globals.named(@name))
    end
  
  end
  
  class GlobalVariables
  
    def self.init(mod)
      @module ||= mod
      @variables ||= {}
    end
  
    def self.add(name, value, builder)
      return @variables[name] = GlobalVariable.new(name, value, @module, builder)
    end
    
    def self.named(name)
      return @variables[name]
    end
  
  end
end