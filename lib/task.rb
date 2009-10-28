require "#{$script_dir}/source-file"
require "#{$script_dir}/file-set"
require 'set'

class Task
  attr_reader :included_files, :assets

  @@options={}
  @@options_type={}
  
  def self.declare_option(option_name, default_value=nil, option_type=nil)
    if (default_value.instance_of?(Class))
      option_type= default_value
      default_value= nil
    end
    
    if (!option_type && default_value)
      option_type= default_value.class
    end

    @@options[option_name]= default_value
    @@options_type[option_name]= case
      when option_type==FileSet
        self.method(:option_to_fileset)
      when option_type==Fixnum
        self.method(:option_to_number)
      when option_type==Array
        self.method(:option_to_array)
      else
        self.method(:option_to_string)
      end
  end

  def self.option_to_fileset(value)
    FileSet.new(value)
  end
  
  def self.option_to_array(value)
    case
      when value.is_a?(String)
        value.split(/\s*,\s*/)
      when value.is_a?(Array)
        value
      else
        [value]
    end
  end
  
  def self.option_to_string(value)
    "#{value}"
  end

  def self.option_to_number(value)
    value.to_i
  end
  
  declare_option :version
  declare_option :name
  declare_option :tasks, Array
  declare_option :targets, Array
  declare_option :mode
  declare_option :remove_prefix
  declare_option :external_projects, Array.new
  
  def initialize(target, options)
    @target= target
    @included_files= []
    
    @files_to_include= []
    @files_to_exclude= []
    @assets= Set.new
    @probed= Set.new
    
    @options= options
    if (@options.remove_prefix)
      SourceFile.root_folder= @options.remove_prefix
    end
  end

  def self.options_hash
    @@options
  end
  
  def self.set_global_options(hash)
    
    @@options.each_pair { |key, value|
      
      type= @@options_type[key]
      
      if (hash.has_key?(key))
        @@options[key]= type.call(hash[key])
        hash.delete(key)
        next
      end

      hash_key= "#{key}".gsub('_', '-')
      if (hash.has_key?(hash_key))
        @@options[key]= type.call(hash[hash_key])
        hash.delete(hash_key)
      end

      hash_key= "#{key}".gsub('_', ' ')
      if (hash.has_key?(hash_key))
        @@options[key]= type.call(hash[hash_key])
        hash.delete(hash_key)
      end
    }
    
  end
  
  def self.options(settings=nil)
    s= Struct.new(*@@options.keys).new(*@@options.values)
    return s if !settings
    
    members= @@options.keys

    members.each { |m|
      type= @@options_type[m]
      m= m.to_s
      
      key= m.gsub('_', '-')
      if (settings.key?(key))
        s[m]= type.call(settings[key])
        settings.delete(key)
      end
      key= m.gsub('_', ' ')
      if (settings.key?(key))
        s[m]= type.call(settings[key])
        settings.delete(key)
      end
    }
  
    s
  end
  
  @@tasks= []
  def self.inherited(subclass)
    @@tasks << subclass
  end
  
  def self.available_tasks
    @@tasks
  end

  def self.task_name
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
