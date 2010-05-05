module Distil
  
  class DistilProject < Project
    
    attr_reader :project_file
    attr_accessor :external
    
    option :mode, DEBUG_MODE
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
      
      super(project_info, parent)

      load_external_projects
      
    end

    def targets
      @targets if @targets

      @targets= []
      @extras.each { |key, value|
        target= Target.from_config_key(key)
        next if !target
        @targets << target.new(value, self)
      }
      @targets
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
      if external
        wd= Dir.getwd
        Dir.chdir(path)
        system "distil --mode=#{mode}"
        Dir.chdir(wd)
        return
      end
      
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
        # external projects aren't included in the output when weak linked,
        # they are just expected to be there, somehow. Like magic.
        return if WEAK_LINKAGE==project.linkage
        
        project_folder= File.join(output_folder, project.name)
        
        FileUtils.rm_r(project_folder) if File.directory?(project_folder)
        FileUtils.unlink(project_folder) if File.symlink?(project_folder)

        if DEBUG_MODE==mode
          FileUtils.symlink(File.expand_path(project.output_folder), project_folder)
        else
          FileUtils.cp_r(File.expand_path(project.output_folder), project_folder)
        end
        project.output_folder= project_folder
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
