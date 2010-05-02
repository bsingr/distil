module Distil
  
  FRAMEWORK_TYPE = "framework"
  APP_TYPE = "application"

  WEAK_LINKAGE = 'weak'
  INCLUDE_LINKAGE = 'include'
  LAZY_LINKAGE = 'lazy'
  
  DEBUG_MODE = 'debug'
  RELEASE_MODE = 'release'

  class Project < Configurable

    include ErrorReporter

    option :version, String
    option :name, String
    option :path, String
    option :output_folder, ProjectPath, "build/$(mode)", :aliases=>['output']
    option :source_folder, ProjectPath, "", :aliases=>['source']
    option :type, String, FRAMEWORK_TYPE
    option :linkage, WEAK_LINKAGE

    option :import_name, ProjectPath, "$(output_folder)/$(name)-debug.$(product_extension)", :aliases=>['import']
    option :concatenated_name, ProjectPath, "$(output_folder)/$(name)-uncompressed.$(product_extension)", :aliases=>['concatenated']
    option :debug_name, ProjectPath, "$(output_folder)/$(name)-debug.$(product_extension)", :aliases=>['debug']
    option :minified_name, ProjectPath, "$(output_folder)/$(name).$(product_extension)", :aliases=>['minified']
    option :compressed_name, ProjectPath, "$(output_folder)/$(name).$(product_extension).gz", :aliases=>['compressed']


    def initialize(config, parent=nil)
      super(config, parent)
      
      FileUtils.mkdir_p(output_folder)
    end
    
    def self.from_config(config, parent=nil)

      if config.is_a?(String)
        string= config
        config= { "name" => File.basename(config, ".*") }
        full_path= File.expand_path(string)
        if File.exist?(full_path) && File.file?(full_path)
          config["path"]= File.dirname(full_path)
        else
          config["path"]= full_path
        end
      end
      
      config["mode"]||= parent.mode if parent
        
      path= config["path"]
      if !path
        ErrorReporter.error "No path for project: #{config["name"]}"
        return nil
      end
      
      if !File.directory?(path)
        ErrorReporter.error "Path is not valid for project: #{config["name"]}"
        return nil
      end
      
      basename= File.basename(path)
      
      case
      when exist?(path, "#{basename}.jsproj")
        project= DistilProject.new(File.join(path, "#{basename}.jsproj"), config)
        project.external= true
      when exist?(path, "Makefile") || exist?(path, "makefile")
        project= ExternalProject.new(config)
        project.build_command ||= "make"
      when exist?(path, "Rakefile") || exist?(path, "rakefile")
        project= ExternalProject.new(config)
        project.build_command ||= "rake"
      when exist?(path, "Jakefile") || exist?(path, "jakefile")
        project= ExternalProject.new(config)
        project.build_command ||= "jake"
      else
        ErrorReporter.error "Could not determine type for project: #{config["name"]}"
      end
      return project
      
    end
    
    def build
    end

  end
  
end

require 'distil/project/external-project'
require 'distil/project/distil-project'