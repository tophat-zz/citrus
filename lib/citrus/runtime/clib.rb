module Citrus
  module Runtime
  
    @ct.declare(:puts, [:string], :int)
    @ct.declare(:read, [:int, :string, :int], :int)
    @ct.declare(:exit, [:int], :int)
  
  end
end