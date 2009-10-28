require "#{$script_dir}/task"
require "set"

class Target
  attr_reader :name, :tasks
  attr_accessor :warning_count, :error_count

  def initialize(name, settings)
    @name= name
    @@current= self
    
    if (settings.is_a?(Array))
      settings= { "include"=>settings }
    end

    @options= Task.options(settings)

    FileUtils.mkdir_p(@options.output_folder)
    
    @tasks= []

    Task.available_tasks.each { |t|
      next if (!t.task_name)  
      next if (@options.tasks && !@options.tasks.include?(t.task_name))

      @tasks << t.new(self, @options)
    }

    @warning_count=0
    @error_count=0
  end

  def self.current
    @@current
  end
  
  def error(message, file="", line_number=0)
    if (file && line_number)
      printf("%s:%d: error: %s\n", file, line_number, message)
    else
      printf("error: %s\n", message)
    end
    @error_count+=1
  end
  
  def warning(message, file="", line_number=0)
    if (file && line_number)
      printf("%s:%d: warning: %s\n", file, line_number, message)
    else
      printf("warning: %s\n", message)
    end
    @warning_count+=1
  end
  
  def find_file(file)
    Task.options.external_projects.each { |project|
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
      t.validate_files
      t.document_files
      t.process_files
    }
  end

  def finish
    assets= Set.new
    
    @tasks.each { |t|
      t.finish
      assets.merge(t.assets)
    }

    # puts "\nincluded:"
    # @included_files.each { |f| puts f.file_path }
    # 
    # puts "\nordered:"
    # @ordered_files.each { |f| puts f.file_path }
    # puts "\nassets:"
    # assets.each { |a| puts a.file_path }
    
    folders= assets.map { |a|
      short_folder_name= File.dirname(a.file_path).split("/")[0]
      if ("."==short_folder_name)
        [a.file_path, a.relative_to_folder(@options.output_folder)]
      else      
        short_folder_regex= /.*\/#{Regexp.escape(short_folder_name)}\//
        # puts "#{a.file_path}: #{short_folder_regex.inspect}: #{a.relative_to_folder(@options.output_folder)}"
        relative_folder_name= (a.relative_to_folder(@options.output_folder))[short_folder_regex]
        [short_folder_name, relative_folder_name]
      end
    }
    folders.compact!
    folders.uniq!
    
    # puts "\nfolders:"
    # folders.each { |f| puts f.inspect }
    
    folders.each { |f|
      target_folder= "#{@options.output_folder}/#{f[0]}"
      FileUtils.rm target_folder if File.symlink?(target_folder)
      # FileUtils.rm_r target_folder if File.exists?(target_folder)
    }
    
    if ("release"==@options.mode)
      assets.each { |a| a.copy_to(@options.output_folder) }
    else
      folders.each { |f|
        target_folder= "#{@options.output_folder}/#{f[0]}"
        source_folder= f[1]
        File.symlink source_folder, target_folder
      }
    end

    @tasks.each { |t|
      t.cleanup
    }
    
    puts "#{@error_count} error(s), #{@warning_count} warning(s)"
  end
  
end
