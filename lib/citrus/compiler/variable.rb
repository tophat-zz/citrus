module Citrus
  class Variable
    
    attr_reader :type
    #attr_reader :pointer
    
    def initialize(value, builder)
      @value = nil
      if value.is_a?(Citrus::Array)
        @value = value
        @type = LLVM::Type(value.pointer)
      else
        @type = LLVM::Type(value)
      end
      build_initialize(value, builder)
    end
    
    def assign(value, builder)
      if value.is_a?(Citrus::Array)
        @value = value
        @type = LLVM::Type(value.pointer)
      end
      build_assign(value, builder)
    end
    
    def value(builder)
      val = build_load(builder)
      return @value.nil? ? val : @value
    end
    
    private
    
    def build_initialize(value, builder)
      if value.is_a?(Citrus::Array)
        @pointer = value.pointer
        return
      end
      @pointer = builder.alloca(@type)
      builder.store(value, @pointer)
    end
    
    def build_assign(value, builder)
      if value.is_a?(Citrus::Array)
        @pointer = value.pointer
        return
      end
      type = LLVM::Type(value)
      unless type == @type
        @type = type
        @pointer = builder.alloca(type)
      end
      builder.store(value, @pointer)
    end
    
    def build_load(builder)
      builder.load(@pointer)
    end
  
  end
  
  class GlobalVariable < Variable
    
    def initialize(name, value, mod, builder)
      @name = name
      @module = mod
      super(value, builder)   
    end
    
    private
    
    def build_initialize(value, builder)
      @pointer = @module.globals.add(@type, @name)
      if value.is_a?(Citrus::Array)
        @pointer.initializer = value.pointer
      else
        @pointer.initializer = value
      end
    end
    
    def build_assign(value, builder)
      if value.is_a?(Citrus::Array)
        builder.store(value.pointer, @pointer)
      else
        @type = LLVM::Type(value)
        builder.store(value, @pointer)
      end
    end
    
    def build_load(builder)
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