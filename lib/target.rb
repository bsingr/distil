require "#{$script_dir}/task"
require "set"

class Target < Configurable
  attr_accessor :target_name, :warning_count, :error_count

  option :tasks, Array
  
  def initialize(name, settings, project)
    super(settings, project)
    
    @project= project
    @target_name= name
    @@current= self
    
    @tasks= []

    @extras.each { |task_name, task_settings|
      next if (tasks && !tasks.include?(task_name))
      t= Task.by_name(task_name)
      @tasks << t.new(self, task_settings)
    }

    @warning_count=0
    @error_count=0
  end

  def self.current
    @@current
  end

  def error(message, file="", line_number=0)
    @error_count+=1
    if (file && line_number)
      printf("%s:%d: error: %s\n", file, line_number, message)
    else
      printf("error: %s\n", message)
    end
  end
  
  def warning(message, file="", line_number=0)
    @warning_count+=1
    return if (ignore_warnings)
    if (file && line_number)
      printf("%s:%d: warning: %s\n", file, line_number, message)
    else
      printf("warning: %s\n", message)
    end
  end
  
  def products
    products= []
    @tasks.each { |task|
      products.concat(task.products)
    }
    products
  end
  
  def find_file(file)
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

  def process_files
    @tasks.each { |t|
      t.find_files

      next if !t.need_to_build

      t.validate_files
      t.document_files
      t.process_files
    }
  end

  def finish
    @tasks.each { |t|
      t.finish if t.need_to_build
      t.copy_assets
      # assets.merge(t.assets)
    }


    @tasks.each { |t|
      t.cleanup
    }
    
    puts "#{@error_count} error(s), #{@warning_count} warning(s)#{ignore_warnings ? " ignored" : ""}"
  end
  
end
