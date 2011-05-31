require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "portablecontacts"
    gem.summary = %Q{Portable Contacts client for Ruby}
    gem.description = %Q{A client library for the portable contacts standard}
    gem.email = "pelleb@gmail.com"
    gem.homepage = "http://github.com/grantneufeld/portablecontacts"
    gem.authors = ["Pelle Braendgaard","Grant Neufeld"]
    gem.rubyforge_project = "portablecontact"
    gem.add_dependency('oauth', '>= 0.3.6')
    gem.add_dependency('json')
    gem.add_development_dependency("rspec", '>= 2.0.0')
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %q[--exclude "spec"]
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "portablecontacts #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
