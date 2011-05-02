require "rubygems"
require "treetop"

require "citrus/core"
require "citrus/runtime"
require "citrus/compiler"
require "citrus/exceptions"
require "citrus/nodes"

if File.file?(File.dirname(__FILE__) + "/citrus/grammar.rb")
  # Take compiled one
  require "citrus/grammar"
else
  Treetop.load File.dirname(__FILE__) + "/citrus/grammar.tt"
end

module Citrus
  
  def self.compile(code)
    $compiler = Citrus::Compiler.new
    $parser   = CitrusParser.new
    
    if node = $parser.parse(code)
      node.compile($compiler)
    else
      error(SyntaxError.new)
    end
    
    $compiler
  end
  
  def self.compile_file(file)
    $file = file
    self.compile(File.read(file))
  end
  
end