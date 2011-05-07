module Citrus
  class Array
    
    attr_writer :length
    attr_accessor :pointer
    
    def self.create(values, builder)
      ary = builder.alloca(LLVM::Array(LLVM::Type(values.first), values.size))
      for index in 0...values.size
        ptr = builder.gep(ary, [INT.from_i(0), INT.from_i(index)])
        builder.store(values[index], ptr)
      end
      self.new(ary)
    end
    
    def initialize(pointer, length=nil)
      @pointer = pointer
      @length = length
    end
    
    def length
      unless @length.nil?
        return @length
      else
        return @length = INT.from_i(LLVM::C.LLVMGetArrayLength(LLVM::Type(@pointer).element_type))
      end
    end
  
  end
end