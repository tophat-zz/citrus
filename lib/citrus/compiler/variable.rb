module Citrus
  class Variable
    
    attr_reader :type
    attr_reader :pointer
    
    def initialize(value, builder)
      @value = nil
      if value.is_a?(Citrus::Array)
        @value = value
      end
      @type = LLVM::Type(value.pointer)
      build_initialize(value, builder)
    end
    
    def assign(value, builder)
      if value.is_a?(Citrus::Array)
        @value = value
      end
      @type = LLVM::Type(value.pointer)
      build_assign(value, builder)
    end
    
    def value(builder)
      val = build_load(builder)
      return @value.nil? ? Object.new(val, builder) : @value
    end
    
    private
    
    def build_initialize(value, builder)
      if value.is_a?(Citrus::Array)
        @pointer = value.pointer
        return
      end
      @pointer = builder.alloca(@type)
      builder.store(value.pointer, @pointer)
    end
    
    def build_assign(value, builder)
      if value.is_a?(Citrus::Array)
        @pointer = value.pointer
        return
      end
      builder.store(value.pointer, @pointer)
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
      @pointer.initializer = Object.type.null
      builder.store(value.pointer, @pointer)
    end
    
    def build_assign(value, builder)
      builder.store(value.pointer, @pointer)
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