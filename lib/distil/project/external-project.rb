module Distil
  
  class ExternalProject < Project

    option :name, String
    option :repository
    option :build_command, String, :aliases=>['build']
    option :linkage, WEAK_LINKAGE, :valid_values=> [WEAK_LINKAGE, STRONG_LINKAGE, LAZY_LINKAGE]

    option :import_name, OutputPath, "$(name)-debug.$(extension)", :aliases=>['import']
    option :concatenated_name, OutputPath, "$(name)-uncompressed.$(extension)", :aliases=>['concatenated']
    option :debug_name, OutputPath, "$(name)-debug.$(extension)", :aliases=>['debug']
    option :minified_name, OutputPath, "$(name).$(extension)", :aliases=>['minified']
    option :compressed_name, OutputPath, "$(name).$(extension).gz", :aliases=>['compressed']
    
    def initialize(config, parent=nil)
      if !config.has_key?("source_folder")
        config["source_folder"]= "build/$(mode)"
      end
      super(config, parent)
      
      @options.output_folder= File.join(parent.output_folder, name)
    end

    def product_name(product_type, extension)
      info= Struct.new(:extension).new(extension)
      name= self.send("#{product_type.to_s}_name")
      Interpolated.value_of(name, info)
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
