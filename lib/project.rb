require "#{$script_dir}/target"

require 'yaml'

class Project < Configurable
  attr_reader :project_file
  
  option :tasks, Array
  option_alias :tasks, :task
  
  option :version, String
  option :project_name, String
  option_alias :project_name, :name
  
  option :targets, Array
  option_alias :targets, :target
  
  option :mode
  option :ignore_warnings, false

  option :external_projects

  option :distileries, Array
  option_alias :distileries, :distilleries
  option_alias :distileries, :distilery
  option_alias :distileries, :distillery
  
  
  def initialize(project_file, settings)
    @@current= self
    @project_file= File.expand_path(project_file)
    Dir.chdir(File.dirname(@project_file))
    
    project_info= YAML.load_file(@project_file)
    settings.merge!(project_info)    
    super(settings)
  end

  @@current=nil
  def self.current
    @@current
  end

  def find_file(file)
    return nil if external_projects.nil?
    
    external_projects.each { |project|
      path= File.expand_path(File.join(project["include"], file))
      if (File.exists?(path))
        source_file= SourceFile.from_path(path)
        source_file.file_path= file
        return source_file
      end
    }
    nil
  end

  def build
    load_distileries
    build_external_projects
    build_targets
  end
  
  def load_distileries
    return if distileries.nil?
    
    distileries.each { |d|
      if (File.exists?(d))
        require d
        next
      end
      path= Gem.required_location(d, 'distilery.rb')
      if (path.nil?)
        puts "Missing distilery: #{d}"
      end
      next if path.nil?
      require path
    }
  end
  
  def build_external_projects
    projects= external_projects
    if (projects.nil?)
      @options.external_projects= []
      return
    end
    
    # Handle external projects
    if (projects.is_a?(String))
      projects= projects.split(/\s*,\s*/)
    end
    
    if (projects.is_a?(Array))
      projects= projects.map { |folder|
        {
          "folder"=>folder
        }
      }
    else
      projects= projects.map { |folder, project|
        
        if project.is_a?(String)
          project= {
            "url"=>project
          }
        end
      
        defaults= {
          "folder"=>folder,
          "build"=>"distil",
          "include"=>File.join(folder, "build")
        }

        defaults.merge(project)
      }
    end
    
    # build or get each project
    projects.each { |project|
      
      if (project.key?("folder") && !File.directory?(project["folder"]) && !File.symlink?(project["folder"]))
        if (project["url"])
          url= project["url"]
          system "svn co #{url} #{project["folder"]}"
        else
          puts "#{@project_file}: external project folder missing: #{project["folder"]}"
          exit
        end
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
    
    @options.external_projects= projects
  end
  
  def build_targets
    
    @extras.each { |section, value|
      
      next if (options.targets && !options.targets.include?(section))
      next if ((!options.targets || !options.targets.include?(section)) &&
           value.is_a?(Hash) && value.has_key?("enabled") && !value["enabled"])

      puts
      puts "#{project_name}/#{section}:"
      puts

      task= Task.by_name(section) || Task.by_product_name(section)
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
