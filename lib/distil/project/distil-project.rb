module Distil
  
  class DistilProject < Project
    
    attr_reader :project_file

    option :ignore_warnings, false

    option :minify, true
    option :compress, true

    option :external_projects, [], :aliases=>['use', 'uses']
    option :distileries, Array, :aliases=>['distilleries', 'distilery', 'distillery']
  
  
    def initialize(project_file, settings={}, parent=nil)
      @project_file= File.expand_path(project_file)
      @projects_by_name={}

      project_info= YAML.load_file(@project_file)
      project_info.merge!(settings)
      project_info["path"]= File.dirname(@project_file)
      
      begin
        super(project_info, parent)
      rescue ValidationError
        $stderr.print "#{APP_NAME}: #{project_file}: #{$!}\n"
        exit 1
      end

      load_external_projects
    end

    def find_file(file)
      return nil if external_projects.nil?
      parts= file.split(File::SEPARATOR)
      project_name= parts[0]

      return nil if !@projects_by_name.has_key?(project_name)

      project= @projects_by_name[project_name]

      return SourceFile::from_path(import_name) if 1==parts.length
        
      SourceFile::from_path(File.join(project.source_folder, *parts[1..-1]))
    end

    def load_external_projects
      return if !external_projects

      self.external_projects= external_projects.map { |config|
        project= Project.from_config(config, self)
        next if !project
        @projects_by_name[project.name]= project
      }
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
      external_projects.each { |project|
        project.build
      }
    end

    def build_targets
      puts "\n#{name}:\n\n"
      targets.each { |target|
        target.build
      }
      report
    end
  end
  
end  
