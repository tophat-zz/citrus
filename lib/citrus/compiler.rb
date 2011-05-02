require "citrus/compiler/generator"
require "citrus/compiler/block"
require "citrus/compiler/function"
require "citrus/compiler/variable"
require "citrus/compiler/global_strings"

require "tempfile"

module Citrus
  class Compiler
    
    attr_reader :generator
    attr_reader :module
    
    def initialize
      @module = LLVM::Module.create("Citrus")
      GlobalVariables.init(@module)
      GlobalFunctions.init(@module)
      @function = @module.functions.add("main", LLVM::Type.function([INT, LLVM::Type.pointer(PCHAR)], INT))
      @generator = Generator.new(@module, @function)
      GlobalStrings.init(@generator.builder)
    end
    
    def preamble
      Runtime.build_lib(@generator)
    end
    
    def finish
      @generator.builder.ret(INT.from_i(0))
      @generator.finish
    end
    
    def run
      @engine = LLVM::ExecutionEngine.create_jit_compiler(@module)
      @engine.run_function(@function, 0, 0)
    end
    
    def to_file(file)
      @module.write_bitcode(file)
    end
    
    def compile(file)
      #bc = Tempfile.new("#{file}.bc", "/tmp")
      #as = Tempfile.new("#{file}.s", "/tmp")
      to_file("#{file}.ctc.bc")
      tool = LLVM.bin_path.empty? ? "llc" : File.join(LLVM.bin_path, "llc")
      %x[#{tool} #{file}.ctc.bc -o #{file}.ctc.s]
      %x[gcc #{file}.ctc.s -o #{file}]
      File.delete("#{file}.ctc.bc")
      File.delete("#{file}.ctc.s")
      #bc.close!
      #as.close!
    end
    
    def optimize
      PassManager.new(@engine).run(@module) unless @engine.nil?
    end
    
    def inspect
      @module.dump
    end
    
  end   
end
      