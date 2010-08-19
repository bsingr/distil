require 'rubygems'
require 'rake/gempackagetask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'distil'
    gemspec.authors= ["Jeff Watkins"]
    gemspec.summary= "A build tool for Javascript and CSS that takes advantage of best-of-breed helper applications Javascript Lint and JSDoc Toolkit"
    gemspec.homepage= "http://github/jeffwatkins/distil"
    gemspec.description= gemspec.summary
    gemspec.files= Dir['assets/*', 'lib/**/*', 'bin/*', '[A-Za-z]*', 'vendor/**/*']
    gemspec.files.reject! { |f| File.directory?(f) }
    gemspec.executables= ['distil']
    gemspec.extensions= ['vendor/extconf.rb']
    gemspec.add_dependency('json', '>= 1.4.3')
    gemspec.add_dependency('rubyzip', '>=0.9.4')
  end

  Jeweler::GemcutterTasks.new

  task :push => "gemcutter:release"

rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

namespace :git do
  namespace :submodules do
    desc "Initialize git submodules"
    task :init do
      system "git submodule init"
      system "git submodule update"
    end
  end
end

task :"gemspec:generate" => :"git:submodules:init"

task :default => [ :build ] do
    puts "generated latest version"
end
