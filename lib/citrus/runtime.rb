module Citrus
  module Runtime
    
    def self.build_lib(generator)
      @ct = generator
      require 'citrus/runtime/clib'
      require 'citrus/runtime/syslib'
      require 'citrus/runtime/stdlib'
    end
    
    def self.sprintf
      unless @sprintf
        return @sprintf = @ct.module.functions.add("__sprintf_chk", [PCHAR, I32, INT, PCHAR], I32, :varargs => true)
      else
        return @sprintf
      end
    end
    
    def self.printf
      unless @printf
        return @printf = @ct.module.functions.add("printf", [PCHAR], I32, :varargs => true)
      else
        return @printf
      end
    end
    
  end
end