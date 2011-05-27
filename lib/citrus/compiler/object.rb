module Citrus
  class Object
    
    # Structure Type
    OBJ_TYPE = LLVM::Struct(I32, PCHAR, BOOL, INT, FLOAT)
    
    attr_reader :pointer
    
    def self.type
      return LLVM::Type.pointer(OBJ_TYPE)
    end
    
    def self.create(value, builder)
      dint = INT.from_i(0)
      dbool = BOOL.from_i(1)
      dfloat = FLOAT.from_f(0.0)
      dstr = GlobalStrings.pointer("")
      pointer = builder.alloca(OBJ_TYPE)
      case LLVM::Type(value)
      when INT.type
        struct = LLVM::ConstantStruct.const([I32.from_i(ITYPE), dstr, dbool, dint, dfloat])
        builder.store(struct, pointer)
        iptr = builder.struct_gep(pointer, 3)
        builder.store(value, iptr)
      when FLOAT.type
        struct = LLVM::ConstantStruct.const([I32.from_i(FTYPE), dstr, dbool, dint, dfloat])
        builder.store(struct, pointer)
        fptr = builder.struct_gep(pointer, 4)
        builder.store(value, fptr)
      when PCHAR
        struct = LLVM::ConstantStruct.const([I32.from_i(STYPE), dstr, dbool, dint, dfloat])
        builder.store(struct, pointer)
        sptr = builder.struct_gep(pointer, 1)
        builder.store(value, sptr)
      when BOOL.type
        struct = LLVM::ConstantStruct.const([I32.from_i(BTYPE), dstr, dbool, dint, dfloat])
        builder.store(struct, pointer)
        bptr = builder.struct_gep(pointer, 2)
        builder.store(value, bptr)
      end
      self.new(pointer)
    end
    
    def from_va(builder)
    end
    
    def initialize(pointer, type_or_builder=nil)
      @pointer = pointer
    end
    
    def type?(type, builder)
      case type
      when PCHAR
        return builder.icmp(:eq, builder.load(builder.struct_gep(@pointer, 0)), I32.from_i(STYPE))
      when BOOL.type
        return builder.icmp(:eq, builder.load(builder.struct_gep(@pointer, 0)), I32.from_i(BTYPE))
      when INT.type
        return builder.icmp(:eq, builder.load(builder.struct_gep(@pointer, 0)), I32.from_i(ITYPE))
      when FLOAT.type
        return builder.icmp(:eq, builder.load(builder.struct_gep(@pointer, 0)), I32.from_i(FTYPE))
      end
    end
    
    def primitive(type, generator)
      case type
      when PCHAR
        return to_s(generator)
      when BOOL.type
        return to_b(generator)
      when INT.type
        return to_i(generator)
      when FLOAT.type
        return to_f(generator)
      end
    end
    
    def to_s(generator)
      generator.builder.call(generator.module.functions.named(O2S), @pointer)
    end
    
    def to_b(generator)
      generator.builder.call(generator.module.functions.named(O2B), @pointer)
    end
    
    def to_i(generator)
      generator.builder.call(generator.module.functions.named(O2I), @pointer)
    end
    
    def to_f(generator)
      generator.builder.call(generator.module.functions.named(O2F), @pointer)
    end
  
  end
end