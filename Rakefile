require 'rake/gempackagetask'
require 'rake/rdoctask'

Rake::RDocTask.new do |t|
  t.rdoc_files   = Dir['lib/**/*.rb']
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  
  s.name = 'citrus'
  s.version = '0.8.0'
  s.summary = "Linear compiler written in Ruby"
  
  s.requirements << "LLVM v2.9"
  s.add_dependency('treetop', '>= 1.4.9')
  s.add_dependency('ruby-llvm', '>= 2.9.1')
  s.files = Dir['lib/**/*.rb', 'bin/*', 'example/*']
  s.require_path = 'lib'
  s.bindir = 'bin'
  
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE']
  
  s.author = "Mac Malone"
  s.homepage = "http://github.com/ShadowSides/citrus"
end

Rake::GemPackageTask.new(spec) do |t|
end