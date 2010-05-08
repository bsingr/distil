require 'rubygems'
require 'rake/gempackagetask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'distil'
    gemspec.authors= ["Jeff Watkins"]
    gemspec.summary= "A build tool for Javascript and CSS that takes advantage of best-of-breed helper applications Javascript Lint and JSDoc Toolkit"
    gemspec.homepage= "http://code.google.com/p/distil-js/"
    gemspec.description= gemspec.summary
    gemspec.files= Dir['lib/**/*', 'bin/*', '[A-Za-z]*', 'vendor/**/*']
    gemspec.files.reject! { |f| File.directory?(f) }
    gemspec.executables= ['distil']
    gemspec.extensions= ['vendor/extconf.rb']
  end

  Jeweler::GemcutterTasks.new

  task :push => "gemcutter:release"

rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

task :default => [ :build ] do
    puts "generated latest version"
end