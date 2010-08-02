module Distil
  
  class DistilProject < Project
    
    attr_reader :project_file, :targets

    option :ignore_warnings, false
    option :warnings_are_errors, false
    option :external_projects, [], :aliases=>['external']
    option :distileries, Array, :aliases=>['distilleries', 'distilery', 'distillery']
  
  
    def initialize(project_file, settings={}, parent=nil)
      
      begin

        @project_file= File.expand_path(project_file)
        @projects_by_name={}

        project_info= YAML.load_file(@project_file)
        project_info["path"]= File.dirname(@project_file)

        super(project_info, parent)
        get_options(settings, parent)

        FileUtils.mkdir_p(output_folder)

        load_external_projects
        find_targets
        load_distileries
        
      rescue ValidationError => err
        puts "#{APP_NAME}: #{SourceFile.path_relative_to_folder(project_file, Dir.pwd)}: #{err.message}\n"
        exit 1
      end
      
    end

    def find_targets
      @targets= []
      target_list= @extras['targets']
    
      if !target_list
        @targets << Target.new(@extras.clone, self)
        return @targets
      end

      @targets= target_list.map { |target|
        Target.new(target, self)
      }
    end
    
    def load_external_projects
      return if !external_projects
      projects= []
      
      external_projects.each { |config|
        project= Project.from_config(config, self)
        next if !project
        projects << project
        @projects_by_name[project.name]= project
      }
      
      self.external_projects= projects
    end

    def external_project_with_name(name)
      @projects_by_name[name]
    end
    
    def launch
      build if !up_to_date
      
      require 'webrick'
      config= {
        :Port => 8888
      }

      server= WEBrick::HTTPServer.new(config)
      server.mount("/", WEBrick::HTTPServlet::FileHandler, output_folder)

      ['INT', 'TERM'].each { |signal|
         trap(signal){ server.shutdown} 
      }
      b= Browser.new
      b.open("http://localhost:8888/")
      server.start
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

    def up_to_date
      return false if !external_projects.all?{ |project| project.up_to_date }
      return targets.all? { |target| target.up_to_date }
    end

    def clean
      # clean_external_projects
      targets.each { |target|
        target.clean
      }
    end
    
    def build
      build_external_projects
      build_targets
    end

    def build_external_projects
      external_projects.each { |project|
        project.build
      }
    end

    def build_targets
      targets.each { |target|
        target.build
      }
    end

    def find_file(file, source_file=nil)
      return nil if external_projects.nil?
      
      parts= file.split(File::SEPARATOR)
      project_name= parts[0]

      external_project= external_project_with_name(project_name)
      return nil if !external_project

      if 1==parts.length
        return SourceFile::from_path(external_project.product_name(:import, source_file.content_type))
      else
        return SourceFile::from_path(File.join(external_project.output_folder, *parts[1..-1]))
      end
    end
    
  end
  
end  
