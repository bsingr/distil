module Distil
  
  class Project < Configurable

    include ErrorReporter

    option :output_folder, ProjectPath, "build/$(mode)", :aliases=>['output']
    option :source_folder, ProjectPath, ""
    
    option :path, String
    option :mode, DEBUG_MODE, :valid_values=>[DEBUG_MODE, RELEASE_MODE]
    option :force
    
    def build
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
        project_file= File.join(path, "#{basename}.jsproj")
        project_info= YAML.load_file(project_file)
        project_info.merge!(config)
        project_info["path"]= path
        project= ExternalProject.new(project_info, parent)
        if parent
          project.build_command ||= "distil --mode=#{parent.mode} --force=#{parent.force}"
        else
          project.build_command ||= "distil"
        end
      when exist?(path, "Makefile") || exist?(path, "makefile")
        project= ExternalProject.new(config, parent)
        project.build_command ||= "make"
      when exist?(path, "Rakefile") || exist?(path, "rakefile")
        project= ExternalProject.new(config, parent)
        project.build_command ||= "rake"
      when exist?(path, "Jakefile") || exist?(path, "jakefile")
        project= ExternalProject.new(config, parent)
        project.build_command ||= "jake"
      else
        ErrorReporter.error "Could not determine type for project: #{config["name"]}"
      end
      return project
      
    end
    
  end
  
end

require 'distil/project/external-project'
require 'distil/project/distil-project'