module Distil
  
  class ExternalProject < Project

    option :repository
    option :build_command, String, :aliases=>['build']
    
    def initialize(config, parent=nil)
      if (!config.has_key?("source_folder") && !config.has_key?("source"))
        config["source_folder"]= "build/$(mode)"
      end
      super(config, parent)
      
      @options.output_folder= File.join(parent.output_folder, name)
    end
    
    def build
      wd= Dir.getwd
      Dir.chdir(path)
      system build_command
      Dir.chdir(wd)

      # external projects aren't included in the output when weak linked,
      # they are just expected to be there, somehow. Like magic.
      return if WEAK_LINKAGE==linkage
    
      FileUtils.rm_r(output_folder) if File.directory?(output_folder)
      FileUtils.unlink(output_folder) if File.symlink?(output_folder)

      if DEBUG_MODE==mode
        FileUtils.symlink(File.expand_path(source_folder), output_folder)
      else
        FileUtils.cp_r(File.expand_path(source_folder), output_folder)
      end
    end
    
  end
  
end
