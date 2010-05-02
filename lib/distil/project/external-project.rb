module Distil
  
  class ExternalProject < Project

    option :repository
    option :build_command, String, :aliases=>['build']
    
    def build
      wd= Dir.getwd
      Dir.chdir(path)
      system build_command
      Dir.chdir(wd)
    end
    
  end
  
end
