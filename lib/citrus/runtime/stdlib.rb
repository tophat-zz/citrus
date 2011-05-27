module Citrus
  module Runtime
  
    @ct.assign_global(ERR_GLOBAL, @ct.string(""))
    @ct.assign_global(STS_GLOBAL, @ct.number(0))
    
    @ct.function("raise", ["msg"]) do |gf|
      gf.assign_global(ERR_GLOBAL, gf.load("msg"))
      gf.assign_global(STS_GLOBAL, gf.number(1))
    end
    
    @ct.function("print", ["msg"]) do |gf|
      gf.builder.call(Runtime.printf, GlobalStrings.pointer("%s"), gf.load("msg").to_s(gf))
    end
    
  end
end