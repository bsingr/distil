require "#{$script_dir}/task"
require "set"

class Target
  attr_reader :tasks, :included_files
  attr_accessor :warning_count, :error_count
  
  def initialize(name, settings)
    if (settings.is_a?(Array))
      include_files= settings
      exclude_files= Array.new
      test_files= Array.new
      @options= Task.options({})
    else
      include_files= settings['include'] || Array.new
      exclude_files= settings['exclude'] || Array.new
      test_files= settings['test'] || Array.new
      @options= Task.options(settings)
    end

    FileUtils.mkdir_p(@options.output_folder)
    
    @tasks= []

    Task.available_tasks.each { |t|
      next if (!t.task_name)  
      next if (@options.tasks && !@options.tasks.include?(t.task_name))

      @tasks << t.new(name, @options)
    }

    @included_files= Array.new
    @excluded_files= Set.new
    @assets= Set.new
    @probed_files= Set.new
    @ordered_files= Array.new
    
    @warning_count=0
    @error_count=0
    
    exclude_files.each { |f| self.exclude_file(f) }
    include_files.each { |f| self.include_file(f) }
  end

  def self.current
    @@current
  end
  
  def self.current=(target)
    @@current=target
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
    @options.external.each { |i|
      path= File.expand_path(File.join(i, file))
      if (File.exists?(path))
        source_file= SourceFile.from_path(path)
        source_file.file_path= file
        return source_file
      end
    }
  end
  
  def include_file(file)
    full_path= File.expand_path(file)

    if File.directory?(full_path)
      Dir.foreach(full_path) { |f|
          next if ('.'==f[/^\./])
          include_file(File.join(full_path, f))
      }
    else
      if (File.exists?(full_path))
        source_file= SourceFile.from_path(full_path)
      else
        source_file= find_file(file)
        return if (!source_file)
      end
      
      return if (@included_files.include?(source_file))
      return if (@excluded_files.include?(source_file))
      @included_files << source_file
    end
  end
  
  def exclude_file(file)
    file= File.expand_path(file)
    
    if File.directory?(file)
      Dir.foreach(file) { |f|
          next if ('.'==f[/^\./])
          exclude_file(File.join(file, f))
      }
    else
      source_file= SourceFile.from_path(file)
      
      return if (@excluded_files.include?(source_file))
      @excluded_files << source_file
    end
  end

  def process_file(file)
    
    return if (@probed_files.include?(file))
    return if (!@included_files.include?(file))

    @probed_files << file
    
    file.dependencies.each { |d| process_file(d) }
    @ordered_files << file;

    @tasks.each { |t|
      next if (!t.handles_file?(file))
      @assets.merge(file.assets)
      @assets << file
      t.include_file(file)
    }
  end
  
  def process_all_files
    @included_files.each { |f| process_file(f) }
    
    @tasks.each { |t|
      t.validate_files
      t.document_files
      t.process_all_files
    }
  end

  def finish
    @tasks.each { |t| t.finish }

    # puts "\nincluded:"
    # @included_files.each { |f| puts f.file_path }
    # 
    # puts "\nordered:"
    # @ordered_files.each { |f| puts f.file_path }
    # puts "\nassets:"
    # @assets.each { |a| puts a.file_path }
    
    folders= @assets.map { |a|
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
      @assets.each { |a| a.copy_to(@options.output_folder) }
    else
      folders.each { |f|
        target_folder= "#{@options.output_folder}/#{f[0]}"
        source_folder= f[1]
        File.symlink source_folder, target_folder
      }
    end
    
    puts "#{@error_count} error(s), #{@warning_count} warning(s)"
  end
  
end
