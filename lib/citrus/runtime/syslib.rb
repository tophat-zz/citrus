module Citrus
  module Runtime
    
    @ct.module.functions.add(O2S, [Object.type], PCHAR) do |func, object|
      cases = {}
      gen = Generator.new(@ct.module, func)
      pointer = gen.builder.alloca(PCHAR)
      cases[I32.from_i(STYPE)] = gen.block do |gb|
        gb.builder.store(gb.builder.load(gb.builder.struct_gep(object, 1)), pointer)
      end
      cases[I32.from_i(ITYPE)] = gen.block do |gb|
        string = gb.builder.alloca(PCHAR.element_type)
        iptr = gb.builder.load(gb.builder.struct_gep(object, 3))
        gb.builder.call(Runtime.sprintf, string, I32.from_i(0), INT.from_i(25), GlobalStrings.pointer("%d"), iptr)
        gb.builder.store(string, pointer)
      end
      cases[I32.from_i(FTYPE)] = gen.block do |gb|
        string = gb.builder.alloca(PCHAR.element_type)
        fptr = gb.builder.load(gb.builder.struct_gep(object, 4))
        gb.builder.call(Runtime.sprintf, string, I32.from_i(0), INT.from_i(50), GlobalStrings.pointer("%f"), fptr)
        gb.builder.store(string, pointer)
      end
      eb = gen.block do |gb|
        gb.builder.store(GlobalStrings.pointer(""), pointer)
      end
      type = gen.builder.load(gen.builder.struct_gep(object, 0))
      gen.case(type, cases, eb)
      gen.builder.ret(gen.builder.load(pointer))
    end
  
    @ct.module.functions.add(O2B, [Object.type], BOOL) do |func, object|
      cases = {}
      gen = Generator.new(@ct.module, func)
      pointer = gen.builder.alloca(BOOL)
      cases[I32.from_i(BTYPE)] = gen.block do |gb|
        gb.builder.store(gb.builder.load(gb.builder.struct_gep(object, 2)), pointer)
      end
      eb = gen.block do |gb|
        gb.builder.store(BOOL.from_i(1), pointer)
      end
      type = gen.builder.load(gen.builder.struct_gep(object, 0))
      gen.case(type, cases, eb)
      gen.builder.ret(gen.builder.load(pointer))
    end
  
    @ct.module.functions.add(O2I, [Object.type], INT) do |func, object|
      cases = {}
      gen = Generator.new(@ct.module, func)
      pointer = gen.builder.alloca(INT)
      cases[I32.from_i(ITYPE)] = gen.block do |gb|
        iptr = gb.builder.struct_gep(object, 3)
        gb.builder.store(gb.builder.load(iptr), pointer)
      end
      cases[I32.from_i(FTYPE)] = gen.block do |gb|
        fptr = gb.builder.struct_gep(object, 4)
        gb.builder.store(gb.builder.fp2ui(gb.builder.load(fptr), INT), pointer)
      end
      eb = gen.block do |gb|
        gb.builder.store(INT.from_i(0), pointer)
      end
      type = gen.builder.load(gen.builder.struct_gep(object, 0))
      gen.case(type, cases, eb)
      gen.builder.ret(gen.builder.load(pointer))
    end

    @ct.module.functions.add(O2F, [Object.type], FLOAT) do |func, object|
      cases = {}
      gen = Generator.new(@ct.module, func)
      pointer = gen.builder.alloca(FLOAT)
      cases[I32.from_i(FTYPE)] = gen.block do |gb|
        fptr = gb.builder.struct_gep(object, 4)
        gb.builder.store(gb.builder.load(fptr), pointer)
      end
      cases[I32.from_i(ITYPE)] = gen.block do |gb|
        iptr = gb.builder.struct_gep(object, 3)
        gb.builder.store(gb.builder.ui2fp(gb.builder.load(iptr), FLOAT), pointer)
      end
      eb = gen.block do |gb|
        gb.builder.store(FLOAT.from_f(0.0), pointer)
      end
      type = gen.builder.load(gen.builder.struct_gep(object, 0))
      gen.case(type, cases, eb)
      gen.builder.ret(gen.builder.load(pointer))
    end
=begin Not Working    
    # Comparison
    for data in Hash[*CMP_MAPPING.values.map{|n| [Citrus.const_get(n.to_s.upcase.to_sym), n]}.flatten]
      @ct.module.functions.add(data[0], [Object.type, Object.type], Object.type) do |func, obj1, obj2|
        gen = Generator.new(@ct.module, func)
        pointer = gen.builder.alloca(Object.type)
        lval = Object.new(obj1)
        rval = Object.new(obj2)
        tb = gen.block do |gb|
          symbol = "o#{data[1].to_s}".to_sym
          struct = Object.create(gb.builder.fcmp(symbol, lval.to_f(gb), rval.to_f(gb)), gb.builder)
          gb.builder.store(struct.pointer, pointer)
        end
        eb = gen.block do |gb|
          symbol = data[1] == :eq || data[1] == :ne ? data[1] : "s#{data[1].to_s}".to_sym
          struct = Object.create(gb.builder.icmp(symbol, lval.to_i(gb), rval.to_i(gb)), gb.builder)
          gb.builder.store(struct.pointer, pointer)
        end
        cond = gen.builder.or(lval.type?(FLOAT.type, gen.builder), rval.type?(FLOAT.type, gen.builder))
        gen.condition(Object.create(cond, gen.builder), tb, eb)
        val = gen.builder.load(pointer)
        gen.builder.ret(gen.builder.load(pointer))
      end
    end
  
    # Equation
    for data in Hash[*EQU_MAPPING.values.map{|n| [Citrus.const_get(n.to_s.upcase.to_sym), n]}.flatten]
      @ct.module.functions.add(data[0], [Object.type, Object.type], Object.type) do |func, obj1, obj2|
        gen = Generator.new(@ct.module, func)
        pointer = gen.builder.alloca(Object.type)
        lval = Object.new(obj1)
        rval = Object.new(obj2)
        tb = gen.block do |gb|
          symbol = "f#{data[1].to_s}".to_sym
          struct = Object.create(gb.builder.send(symbol, lval.to_f(gb), rval.to_f(gb)), gb.builder)
          gb.builder.store(struct.pointer, pointer)
        end
        eb = gen.block do |gb|
          symbol = data[1] == :div ? :sdiv : data[1]
          struct = Object.create(gb.builder.send(symbol, lval.to_i(gb), rval.to_i(gb)), gb.builder)
          gb.builder.store(struct.pointer, pointer)
        end
        cond = gen.builder.or(lval.type?(FLOAT.type, gen.builder), rval.type?(FLOAT.type, gen.builder))
        gen.condition(Object.create(cond, gen.builder), tb, eb)
        val = gen.builder.load(pointer)
        gen.builder.ret(gen.builder.load(pointer))
      end
    end
=end

  end    
end