require 'set'

module Distil
  
  class Task < Configurable
    attr_reader :target
    
    def initialize(target)
      @target= target
      super({}, target)
    end

    @@tasks= []
    def self.inherited(subclass)
      @@tasks << subclass
    end
  
    def self.tasks
      @@tasks
    end
    
    @@task_aliases= {}
    def self.task_name_alias(name)
      @@task_aliases[name]= self
    end
  
    @@task_index= nil
    def self.task_index
      return @@task_index if @@task_index
      @@task_index= {}
      @@tasks.each { |t|
        next if !t.task_name
        @@task_index[t.task_name]= t
      }
      @@task_index
    end
  
    def self.by_name(taskname)
      self.task_index[taskname] || @@task_aliases[taskname]
    end
  
    def self.task_name
      s= (self.to_s)[/(.*)Task/,1]
      return nil if !s || s.empty?
      s.gsub!(/\w+::/, '')
      s.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1-\2')
      s.gsub!(/([a-z\d])([A-Z])/,'\1-\2')
      s.downcase
    end

    def task_name
      self.class.task_name
    end

    def project
      target.project
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

    def products
      []
    end
  
    def include_file(file)
    end
    
    def validate_files(files)
    end
  
    def document_files(files)
    end
  
    def process_files(files)
    end
  
  end
  
end

# load all the other task types
Dir.glob("#{LIB_DIR}/distil/task/*-task.rb") { |file|
  require file
}
