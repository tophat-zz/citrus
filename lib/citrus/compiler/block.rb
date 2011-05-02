module Citrus
  class Block
    
    def initialize(mod, function, parent)
      @module = mod
      @function = function
      @parent = parent
      build_block { |g| yield g if block_given? }
    end
    
    def basic_block
      return @generator.basic_block
    end
    alias :bb :basic_block
    
    def locals
      return @generator.locals
    end
    
    private
    
    def build_block
      @generator = Generator.new(@module, @function, @parent)
      yield @generator if block_given?
      @generator.finish
    end
  
  end
end