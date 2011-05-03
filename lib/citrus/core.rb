require "rubygems"

if File.directory?("#{File.dirname(__FILE__)}/../llvm-2.9") # Custom LLVM Loading (for me only)
require "llvm/load"
LLVM.load("#{File.dirname(__FILE__)}/../llvm-2.9")
end

require 'llvm/core'
require 'llvm/execution_engine'
require 'llvm/transforms/scalar'

module Citrus

  LLVM.init_x86

  PCHAR = LLVM::Type.pointer(LLVM::Int8)
  FLOAT = LLVM::Double
  INT   = LLVM::Int
  BOOL  = LLVM::Int1

  CMP_MAPPING = { "==" => :eq,  "!=" => :ne,  ">" => :gt, 
                  ">=" => :ge,  "<" => :lt,  "<=" => :le }
                
  EQU_MAPPING = { "+" => :add,  "-" => :sub,  "/" => :div, "*" => :mul }
  
  DEC_MAPPING = { :bool => BOOL, :float => FLOAT, :int => INT, :string => PCHAR }
  
  ERR_GLOBAL = "$!"
  STS_GLOBAL = "$?"
    
end