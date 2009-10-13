require "#{$script_dir}/source-file"
require 'set'

class Task
  attr_reader :included_files

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
      when option_type==Fixnum
        :to_i
      when option_type==Array
        :to_a
      else
        :to_s
      end
  end

  declare_option :version
  declare_option :name
  declare_option :tasks, Array
  declare_option :targets
  declare_option :mode
  declare_option :remove_prefix
  declare_option :external_projects, Array.new
  
  def initialize(target_name, options)
    @target_name= target_name
    @included_files= []
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
        @@options[key]= hash[key].send(type)
        hash.delete(key)
        next
      end

      hash_key= "#{key}".gsub('_', '-')
      if (hash.has_key?(hash_key))
        @@options[key]= hash[hash_key].send(type)
        hash.delete(hash_key)
      end

      hash_key= "#{key}".gsub('_', ' ')
      if (hash.has_key?(hash_key))
        @@options[key]= hash[hash_key].send(type)
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
        s[m]= settings[key].send(type)
        settings.delete(key)
      end
      key= m.gsub('_', ' ')
      if (settings.key?(key))
        s[m]= settings[key].send(type)
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
  
  def include_file(file)
    return if @included_files.include?(file)
    @included_files << file
  end

  def validate_files
  end
  
  def document_files
  end
  
  def process_all_files
  end
  
  def finish
  end
  
end


# load all the other task types
Dir.glob("#{$script_dir}/tasks/*-task.rb") { |file|
  require file
}
