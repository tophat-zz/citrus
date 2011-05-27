require "rubygems"

if File.directory?("#{File.dirname(__FILE__)}/../llvm-2.9") # Custom LLVM Loading (ignore)
require "llvm/load"
LLVM.load("#{File.dirname(__FILE__)}/../llvm-2.9")
end

require 'llvm/core'
require 'llvm/execution_engine'
require 'llvm/transforms/scalar'

module Citrus

  LLVM.init_x86

  # LLVM Types
  PCHAR = LLVM::Type.pointer(LLVM::Int8)
  FLOAT = LLVM::Double
  INT   = LLVM::Int
  I32   = LLVM::Int32
  BOOL  = LLVM::Int1
  
  # Object Types
  STYPE = 1
  BTYPE = 2
  ITYPE = 3
  FTYPE = 4

  # Compare Mapping
  CMP_MAPPING = { "==" => :eq,  "!=" => :ne,  ">" => :gt, 
                  ">=" => :ge,  "<" => :lt,  "<=" => :le }
  
  # Equation Mapping              
  EQU_MAPPING = { "+" => :add,  "-" => :sub,  "/" => :div, "*" => :mul }
  
  # Declare Mapping
  DEC_MAPPING = { :bool => BOOL, :float => FLOAT, :int => INT, :string => PCHAR }
  
  # Object Conversion Function Names
  O2S = "otos"
  O2B = "otob"
  O2I = "otoi"
  O2F = "otof"
  
  # Comparison Function Names
  EQ = "__eq"
  NE = "__ne"
  GT = "__gt"
  GE = "__ge"
  LT = "__lt"
  LE = "__le"
  
  # Equation Function Names
  ADD = "__add"
  SUB = "__sub"
  MUL = "__mul"
  DIV = "__div"
  
  # Citrus System Global Variable Names
  ERR_GLOBAL = "$!"
  STS_GLOBAL = "$?"
    
end