module Citrus
  module Runtime
    
    def self.build_lib(generator)
      @ct = generator
      build_clib
      build_globals
      build_raise
    end
    
    def self.build_clib
      @ct.declare(:printf, [:string], :int, true)
      @ct.declare(:puts, [:string], :int)
      @ct.declare(:read, [:int, :string, :int], :int)
      @ct.declare(:exit, [:int], :int)
    end
    
    def self.build_globals
      @ct.assign_global(ERR_GLOBAL, @ct.string(""))
      @ct.assign_global(STS_GLOBAL, @ct.number(0))
    end
    
    def self.build_raise
      func = @ct.function("raise", ["msg"]) do |gf|
        gf.assign_global(ERR_GLOBAL, gf.load("msg"))
        gf.assign_global(STS_GLOBAL, gf.number(1))
      end
      func.force_types([PCHAR], INT)
    end
    
  end
end