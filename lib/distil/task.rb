require 'set'

module Distil
  
  class Task < Configurable
    
    def initialize(options, product)
      @product= product
      super(options, product)
    end

    def project
      product.target.project
    end

    def target
      product.target
    end
    
    @@tasks= []
    def self.inherited(subclass)
      @@tasks << subclass
    end
  
    def self.tasks
      @@tasks
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
