require "#{$script_dir}/task"
require "set"

class Target < Configurable
  attr_accessor :target_name, :warning_count, :error_count

  option :tasks, Array
  
  def initialize(name, settings, project)
    super(settings, project)

    @@current= self
    @project= project
    @target_name= name

    @warning_count=0
    @error_count=0
    
    @tasks= []

    @extras.each { |task_name, task_settings|
      next if (tasks && !tasks.include?(task_name))

      if (task_settings.is_a?(Array) || task_settings.is_a?(String))
        task_settings= { "include"=>task_settings }
      end
      
      t= Task.by_name(task_name)
      if (!t.nil?)
        @tasks << t.new(self, task_settings)
        next
      end
      
      t= Task.by_product_name(task_name)
      if (!t.nil?)
        task_settings["output_name"]= task_name[/(.*)\.#{t.output_type}$/,1]
        @tasks << t.new(self, task_settings)
        next
      end

      error("Unknown task: #{task_name}")
    }
  end

  @@current=nil
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
      t.build_assets
    }

    @tasks.each { |t|
      t.cleanup
    }
    
    puts "#{@error_count} error(s), #{@warning_count} warning(s)#{ignore_warnings ? " ignored" : ""}"
  end
  
end
