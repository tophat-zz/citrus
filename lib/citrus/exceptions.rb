module Citrus  
  class SyntaxError < ScriptError  
    def initialize
      line = $parser.failure_line
      col = $parser.failure_column
      str = $parser.input.lines.to_a[line-1]
      str = str.slice(col-1, str.length).delete($/)
      str = "file end" if str.empty?
      super("Unexpected #{str} at #{line}:#{col}.")
    end 
  end
  
  class StandardError < RuntimeError
    def initialize(message)
      line = $parser.input.line_of($pindex)
      col = $parser.input.column_of($pindex)
      super("#{message} at #{line}:#{col}.")
    end
  end
  
  class NameError < StandardError  
    def initialize(name, index=nil, ff=false)
      super("Undefined #{ff ? "" : "local variable or "}function '#{name}")
    end 
  end
  
  class NotFoundError < StandardError
    def initialize(file)
      super("No such file or directory - #{file}")
    end
  end
  
  class ArgumentError < StandardError; end
  
  def self.error(error)
    puts("#{error.message} (#{error.class.to_s.split('::').last})")
    exit(1)
  end  
end