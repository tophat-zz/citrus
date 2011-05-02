module Citrus  
  class SyntaxError < RuntimeError  
    def initialize
      line = $parser.failure_line
      col = $parser.failure_column
      str = $parser.input.lines.to_a[line-1]
      str = str.slice(col-1, str.length).delete($/)
      str = "file end" if str.empty?
      puts $parser.failure_reason
      super("Unexpected #{str} at #{line}:#{col}.")
    end 
  end
  
  class NameError < RuntimeError  
    def initialize(name, index=nil, ff=false)
      index ||= $parser.input.index(name)
      line = $parser.input.line_of(index)
      col = $parser.input.column_of(index)
      super("Undefined #{ff ? "" : "local variable or "}function '#{name}' at #{line}:#{col}.")
    end 
  end
  
  class NotFoundError < StandardError
    def initialize(file)
      super("No such file or directory - #{file}.")
    end
  end
  
  def self.error(error)
    puts("#{error.message} (#{error.class.to_s.split('::').last})")
    exit(1)
  end  
end