module Citrus
  class GlobalStrings
  
    def self.init(builder)
      @builder ||= builder
      @pointers ||= {}
    end
  
    def self.pointer(value)
      if @pointers.has_key?(value)
        return @pointers[value]
      else
        @pointers[value] = @builder.global_string_pointer(value)
        return @pointers[value]
      end
    end
  
  end
end