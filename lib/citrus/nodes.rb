module Citrus
  class ::Treetop::Runtime::SyntaxNode
    def value
      text_value
    end
    
    def codegen(context)
      $pindex = self.interval.first
    end
  end
  Node = Treetop::Runtime::SyntaxNode
  
  class Script < Node
    def compile(compiler)
      compiler.preamble
      expressions.each { |e| e.codegen(compiler.generator) }
      compiler.finish
    end
  end

  class Expression < Node
    def codegen(g)
      statements.map { |s| s.codegen(g) }
    end
  end
  
  class Assign < Node
    def codegen(g)
      g.assign(var.value, expression.codegen(g).last)
    end
  end
  
  class GlobalEq < Node
    def codegen(g)
      g.assign_global(globalvar.value, expression.codegen(g).last)
    end
  end
  
  class IndexEq < Node
    def codegen(g)
      g.assign_index(index.var.value, index.expression.codegen(g).last, expression.codegen(g).last)
    end
  end
  
  class Cmp < Node
    def codegen(g)
      g.compare(op.value, object.codegen(g), expression.codegen(g).last)
    end
  end
  
  class Equation < Node
    def codegen(g)
      g.equate(op.value, object.codegen(g), expression.codegen(g).last)
    end
  end
  
  class Neg < Node
    def codegen(g)
      g.negate(object.codegen(g))
    end
  end
  
  class Not < Node
    def codegen(g)
      g.not(object.codegen(g))
    end
  end
  
  class Require < Node
    def codegen(g)
      file = string.value
      file = File.join(File.dirname($file), file) unless $file.nil?
      error(NotFoundError.new(file)) unless File.exists?(file)
      if node = $parser.parse(File.read(file))
        node.expressions.each { |e| e.codegen(g) }
      else
        error(SyntaxError.new)
      end
    end
  end
  
  class Call < Node
    def codegen(g)
      arg_values = calllist.args.map { |arg| arg.codegen(g) }
      begin
        g.call(func.value, *arg_values)
      rescue
        Citrus.error(NameError.new(func.value, true))
      end
    end
  end
  
  class Def < Node
    def codegen(g)
      args = arglist.args.map do |arg|
        [arg.var.value, arg.default.nil? ? nil : arg.default.codegen(g)]
      end
      g.function(func.value, args) do |gf|
        expressions.each { |e| e.codegen(gf) }
      end
    end
  end
  
  class Return < Node
    def codegen(g)
      g.return(expression.codegen(g).last)
    end
  end
  
  class Begin < Node
    def codegen(g)
      expressions.each { |e| e.codegen(g) }
      rb = g.block do |gb|
        rescue_expressions.each { |e| e.codegen(gb) }
      end
      elb = g.block do |gb|
        else_expressions.each { |e| e.codegen(gb) }
      end
      enb = g.block do |gb|
        ensure_expressions.each { |e| e.codegen(gb) }
      end
      g.begin(rb, elb, enb)
    end
  end
  
  class If < Node
    def codegen(g)
      tb = g.block do |gb|
        expressions.each { |e| e.codegen(gb) }
      end
      elfs = elsifs.each do |elf|
        [elf.condition.codegen(g).last,
        g.block do |gb|
          elf.elements.each { |e| e.expression.codegen(gb) }
        end]
      end
      fb = g.block do |gb|
        else_expressions.each { |e| e.codegen(gb) }
      end
      cond = condition.is_a?(Expression) ? condition.codegen(g).last : condition.codegen(g)
      g.condition(cond, tb, fb, elfs)
    end
  end
  
  class Unless < Node
    def codegen(g)
      tb = g.block do |gb|
        expressions.each { |e| e.codegen(gb) }
      end
      fb = g.block do |gb|
        else_expressions.each { |e| e.codegen(gb) }
      end
      g.condition(g.not(condition.codegen(g).last), tb, fb)
    end
  end
  
  class Case < Node
    def codegen(g)
      cases = {}
      whens.each do |w|
        cases[w.val.codegen(g).last] = g.block do |gb|
          w.elements.each { |e| e.expression.codegen(gb) }
        end
      end
      eb = g.block do |gb|
        else_expressions.each { |e| e.codegen(gb) }
      end
      g.case(switch.codegen(g).last, cases, eb)
    end
  end
  
  class While < Node
    def codegen(g)
      g.preploop(:while)
      g.while(condition.codegen(g).last) do |gw|
        expressions.each { |e| e.codegen(gw) }
      end
    end
  end
  
  class For < Node
    def codegen(g)
      ary = indices.codegen(g)
      g.preploop(:for, var.value, ary)
      g.for(var.value, ary) do |gf|
        expressions.each { |e| e.codegen(gf) }
      end
    end
  end
  
  class Index < Node
    def codegen(g)
      g.load_index(var.codegen(g), expression.codegen(g).last)
    end
  end
  
  class GlobalVar < Node
    def codegen(g)
      g.load_global(value)
    end
  end
  
  class Var < Node
    def codegen(g)
      begin
        g.load(value)
      rescue NoMethodError
        begin
          g.call(value)
        rescue NoMethodError
          Citrus.error(NameError.new(value))
        end
      end
    end
  end
  
  class ArrayNode < Node
    def codegen(g)
      g.array(value.map{ |v| v.codegen(g).last })
    end
  end
  
  class RangeNode < Node
    def codegen(g)
      fval = first.codegen(g)
      lval = last.codegen(g).last
      unless LLVM::Type(fval) == INT.type && LLVM::Type(lval) == INT.type
        Citrus.error(ArgumentError.new("Bad value for range"))
      end
      g.range(first.codegen(g), last.codegen(g).last, self.full?)
    end
  end
  
  class StringNode < Node
    def codegen(g)
      g.string(value)
    end
  end
  
  class SymbolNode < Node
    def codegen(g)
      g.string(value)
    end
  end
  
  class FloatNode < Node
    def codegen(g)
      g.float(value)
    end
  end
  
  class NumberNode < Node
    def codegen(g)
      g.number(value)
    end
  end
  
  class BoolNode < Node
    def codegen(g)
      g.bool(value)
    end
  end
end