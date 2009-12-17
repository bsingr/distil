require "#{$script_dir}/source-file"
require "#{$script_dir}/file-set"
require 'set'
require "#{$script_dir}/configurable"

class Task < Configurable
  attr_reader :included_files, :assets

  option :remove_prefix

  def initialize(target, settings)
    if (settings.is_a?(Array) || settings.is_a?(String))
      settings= { "include"=>settings }
    end
    super(settings, target)
    
    @target= target
    @included_files= []
    
    @files_to_include= []
    @files_to_exclude= []
    @assets= Set.new
    @probed= Set.new
    
    if (remove_prefix)
      SourceFile.root_folder= remove_prefix
    end
  end

  @@tasks= []
  def self.inherited(subclass)
    @@tasks << subclass
  end
  
  def self.available_tasks
    @@tasks
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
    self.task_index[taskname]
  end
  
  def self.task_name
    nil
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
    
    @assets.each { |a|
      stat= File.stat(a)
      if stat.mtime > oldest_product_modification_time
        puts "newer: #{a}"
      end
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
  
  def cleanup
  end
  
end


# load all the other task types
Dir.glob("#{$script_dir}/tasks/*-task.rb") { |file|
  require file
}
