require "#{$script_dir}/filter"
require "#{$script_dir}/source-file"
require "#{$script_dir}/file-set"
require 'set'
require "#{$script_dir}/configurable"

class Task < Configurable
  attr_reader :included_files, :assets

  option :remove_prefix
  option_alias :remove_prefix, :source_folder
  option :validate, true
  
  def initialize(target, settings)
    super(settings, target)
    
    @target= target
    @included_files= []
    
    @files_to_include= []
    @files_to_exclude= []
    @assets= Set.new
    @probed= Set.new
  end

  @@tasks= []
  def self.inherited(subclass)
    @@tasks << subclass
  end
  
  def self.available_tasks
    @@tasks
  end

  @@task_aliases= Hash.new
  def self.task_name_alias(name)
    @@task_aliases[name]= self
  end
  
  @@task_index= nil
  def self.task_index
    return @@task_index if @@task_index
    @@task_index= Hash.new
    @@tasks.each { |t|
      next if !t.task_name
      @@task_index[t.task_name]= t
    }
    @@task_index
  end
  
  def self.by_name(taskname)
    self.task_index[taskname] || @@task_aliases[taskname]
  end
  
  def self.by_product_name(productname)
    @@tasks.select { |t|
      next if !t.respond_to?(:output_type)
      return t if productname[/\.#{t.output_type}$/]
    }
    nil
  end
  
  def self.task_name
    s= (self.to_s)[/(.*)Task/,1]
    s && !s.empty? ?  s.downcase : nil
  end

  def task_name
    self.class.task_name
  end

  def handles_file?(file)
    false
  end
  
  #  Do a simple token substitution. Tokens begin and end with @.
  def replace_tokens(string, params)
  	return string.gsub(/(\n[\t ]*)?@([^@ \t\r\n]*)@/) { |m|
  		key= $2
  		ws= $1
  		value= params[key]||m;
  		if (ws && ws.length)
  			ws + value.split("\n").join(ws);
  		else
  			value
  		end
  	}
  end
  
  def include_file(file)
    return if @probed.include?(file)
    return if @included_files.include?(file)
    return if !handles_file?(file)
    return if !@files_to_include.include?(file)
    return if @files_to_exclude.include?(file)

    @probed << file
    
    file.dependencies.each { |d| include_file(d) }
    @assets.merge(file.assets)
    @assets << file
    @included_files << file
  end

  def find_files
    @probed= Set.new
    @included_files= []
    
    @files_to_include.each { |i| include_file(i) }
    
    # files= @included_files.map { |f| f.to_s }
  end
  
  def products
    []
  end
  
  def need_to_build
    return @need_to_build if !@need_to_build.nil?

    product_modification_times= products.map { |p|
      p=File.expand_path(p)
      return (@need_to_build=true) if !File.exists?(p)
      File.stat(p).mtime
    }
    oldest_product_modification_time= product_modification_times.max
    
    stat= File.stat(Project.current.project_file)
    return (@need_to_build=true) if stat.mtime > oldest_product_modification_time

    @assets.each { |a|
      stat= File.stat(a)
      return (@need_to_build=true) if stat.mtime > oldest_product_modification_time
    }
    
    return (@need_to_build=false)
  end
  
  def validate_files
  end
  
  def document_files
  end
  
  def process_files
  end
  
  def finish
  end
  
  def symlink_assets
    full_root_path= File.expand_path(remove_prefix||"")
    
    folders= []

    assets.each { |a|
      path= a.file_path || a.relative_to_folder(full_root_path)

      parts= File.dirname(path).split(File::SEPARATOR)
      if ('.'==parts[0])
        target_path= File.join(output_folder, path)
        FileUtils.rm target_path if File.exists? target_path
        File.symlink a.relative_to_folder(output_folder), target_path
        next
      end

      for i in (0..parts.length-1)
        f= parts[0..i].join(File::SEPARATOR)
        if !folders.include?(f)
          folders << f
        end
      end
      
    }
    
    folders.sort!
    folders.each { |f|
      src_folder= remove_prefix ? File.join(remove_prefix, f) : f
      src_folder= SourceFile.path_relative_to_folder(File.expand_path(src_folder), output_folder)
      
      target_folder= File.expand_path(File.join(output_folder, f))
      next if File.exists?(target_folder)
      File.symlink src_folder, target_folder
    }
  end
  
  def copy_assets
    assets.each { |a|
      a.copy_to(output_folder, remove_prefix)
    }
  end
  
  def build_assets
    FileUtils.mkdir_p(output_folder)

    if ("release"==mode)
      copy_assets
    else
      symlink_assets
    end
  end
    
  def cleanup
  end
  
end


# load all the other task types
Dir.glob("#{$script_dir}/tasks/*-task.rb") { |file|
  require file
}
