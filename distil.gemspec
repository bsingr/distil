Gem::Specification.new do |s|
  s.name = "distil"
  s.version = "0.6.5"
  s.date= "2009-10-13"
  s.authors= ["Jeff Watkins"]
  s.summary= "A build tool for Javascript and CSS that takes advantage of best-of-breed helper applications Javascript Lint and JSDoc Toolkit"
  s.homepage= "http://code.google.com/p/distil-js/"
  s.description= s.summary
  s.files= Dir['lib/**/*', 'bin/*', '[A-Za-z]*', 'vendor/**/*']
  s.files.reject! { |f| File.directory?(f) }
  s.executables= ['distil']
  s.extensions= ['vendor/extconf.rb']
  
end
