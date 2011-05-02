#!/usr/bin/env ruby -s
$:.unshift File.dirname(__FILE__) + "/../lib"
require "citrus"

if $h
  puts <<-EOS
  
              ~= Citrus =~
  
             To run a file
            citrus fruit.ct
  
    To compile to native application
        citrus -c=lemon lime.ct
  
  EOS
  exit
end

file = ARGV.first
abort "Usage: citrus [-hiO] [-c=file.o] file.or" unless file

g = Citrus.compile_file(File.expand_path(file))
g.optimize unless $O

case
when $i: g.inspect
when $c: g.compile(TrueClass === $c ? File.basename(file, File.extname(file)) : $c)
else     g.run
end