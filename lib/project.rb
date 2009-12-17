require "#{$script_dir}/target"

require 'yaml'

class Project < Configurable

  option :tasks, Array
  option_alias :tasks, :task
  
  option :version, String
  option :project_name, String
  option_alias :project_name, :name
  
  option :targets, Array
  option_alias :targets, :target
  
  option :mode
  option :ignore_warnings, false

  option :external_projects, Array.new

  def initialize(project_file, settings)
    @project_file= File.expand_path(project_file)
    Dir.chdir(File.dirname(@project_file))
    
    project_info= YAML.load_file(@project_file)
    settings.merge!(project_info)    
    super(settings)
  end
  
  def build_external_projects
    
    # Handle external projects
    external_projects.map! { |project|

      if !project.is_a?(String)
        project
      else
        project={
          "folder"=>project,
          "build"=>"distil",
          "include"=>File.join(project, "build")
        }
      end
    }
    
    external_projects.each { |project|
      
      if (project.key?("folder") && !File.directory?(project["folder"]))
        puts "#{@project_file}: external project folder missing: #{project["folder"]}"
        exit
      end
  
      if (!project.key?("include"))
        project["include"]= File.join(project["folder"], "build")
      end
  
      build= project["build"] || "distil"
      wd= Dir.pwd
      Dir.chdir(project["folder"]||project["include"])
      # pass along mode flag to sub-projects
      if (mode)
        build= "#{build} -mode=#{mode}"
      end
      system(build)
      Dir.chdir(wd)
    }

  end
  
  def build_targets
    
    @extras.each { |section, value|
      
      next if (options.targets && !options.targets.include?(section))
      next if ((!options.targets || !options.targets.include?(section)) &&
           value.is_a?(Hash) && value.has_key?("enabled") && !value["enabled"])

      puts
      puts "#{project_name}-#{section}:"
      puts

      task= Task.by_name(section)
      if (task)
        new_value= Hash.new
        new_value[section]= value
        value= new_value
        section= "all"
      end
      
      target= Target.new(section, value, self)
      target.process_files
      target.finish
    }
  end
end
