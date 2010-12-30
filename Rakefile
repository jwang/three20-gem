require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks
#begin
#  Bundler.setup(:default, :development)
#rescue Bundler::BundlerError => e
#  $stderr.puts e.message
#  $stderr.puts "Run `bundle install` to install missing gems"
#  exit e.status_code
#end
require 'rake'

#require 'jeweler'
#Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
#  gem.name = "three20"
#  gem.homepage = "http://github.com/jwang/three20"
#  gem.license = "MIT"
#  gem.summary = %Q{Three20 management gem}
#  gem.description = %Q{Three20 management gem}
#  gem.email = "john@johntwang.com"
#  gem.authors = ["John Wang"]
  
#  gem.executables = ["three20"]
#  gem.files         = `git ls-files`.split("\n")
#  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
#  gem.require_paths = ["lib"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
#  gem.add_runtime_dependency 'thor'
#end

#Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = %w[--color]
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rspec_opts = %w[--color]
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:cucumber)

#namespace :cucumber do
#  desc "Run cucumber features using rcov"
#  Cucumber::Rake::Task.new :rcov => :cleanup_rcov_files do |t|
#    t.cucumber_opts = %w{--format progress}
#    t.rcov = true
#    t.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,features"]
#    t.rcov_opts << %[--text-report --sort coverage --aggregate coverage.data]
#  end
#end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "three20 #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
