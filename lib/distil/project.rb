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

    def self.fetch_project_using_git(options = {})
      uri= options["repository"]
      path= options["path"]
      
      begin
        `git --version 2>/dev/null`
      rescue
        nil
      end
      if $?.nil? || !$?.success?
        raise ValidationError.new("The git version control tool is required to pull this repository: #{uri}")
      end
      
      FileUtils.mkdir_p(path)
      Dir.chdir path do
        init_cmd = "git init"
        init_cmd+= " -q"
        # init_cmd += " -q" if options[:quiet] and not $verbose
        # puts init_cmd if $verbose
        system(init_cmd)
        # base_cmd = "git pull --depth 1 #{uri}"
        base_cmd = "git pull #{uri}"
        base_cmd+= " -q"
        # base_cmd += " -q" if options[:quiet] and not $verbose
        base_cmd += " #{options[:version]}" if options[:version]
        # puts base_cmd if $verbose
        if system(base_cmd)
          # puts "removing: .git .gitignore" if $verbose
          # FileUtils.rm_rf %w(.git .gitignore)
        else
          # rm_rf path
        end
      end
    end
    
    def self.from_config(config, parent=nil)

      if config.is_a?(String)
        string= config
        uri= URI.parse(string)
        
        config= { "name" => File.basename(config, ".*") }
        
        case
        when ['.js', '.css'].include?(File.extname(uri.path))
          config["href"]= uri.to_s
        when uri.scheme
          config["repository"]= uri.to_s
        else
          config["path"]= uri.to_s
        
          full_path= File.expand_path(config["path"])
        
          if File.exist?(full_path) && File.file?(full_path)
            config["path"]= File.dirname(full_path)
          else
            config["path"]= full_path
          end
        end
      end

      if !config["name"]
        case when config["repository"]
          uri= URI.parse(config["repository"])
          config["name"]= File.basename(uri.path, ".*")
        when config["path"]
          config["name"]= File.basename(config["path"], ".*")
        else
          raise ValidationError.new("External project has neither name, path nor repository")
        end
      end

      if config["href"]
        return RemoteProject.new(config, parent)
      end
      
      config["path"]||= "ext/#{config["name"]}"

      if config["repository"] && !File.directory?(config["path"])
        fetch_project_using_git(config)
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

require 'distil/project/remote-project'
require 'distil/project/external-project'
require 'distil/project/distil-project'
