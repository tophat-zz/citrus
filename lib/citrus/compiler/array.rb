module Citrus
  class Array
    
    attr_writer :length
    attr_accessor :pointer
    
    def self.create(values, builder)
      ary = builder.alloca(LLVM::Array(Object.type, values.size))
      for index in 0...values.size
        ptr = builder.gep(ary, [INT.from_i(0), INT.from_i(index)])
        builder.store(values[index].pointer, ptr)
      end
      self.new(ary)
    end
    
    def initialize(pointer, length=nil)
      @pointer = pointer
      @length = length
    end
    
    def length(builder)
      unless @length.nil?
        return @length
      else
        return @length = Object.create(INT.from_i(LLVM::C.LLVMGetArrayLength(LLVM::Type(@pointer).element_type)), builder)
      end
    end
  
  end
end