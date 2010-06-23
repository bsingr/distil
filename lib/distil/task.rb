require 'set'

module Distil
  
  class Task < Configurable
    
    def initialize(options, target)
      @target= target
      super(options, target)
    end

    def project
      target.project
    end

    def target
      @target
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

    def find_files
      []
    end
    
    def include_file(file)
    end

    def process_files(files)
    end
  
  end
  
  # load all the other task types
  Dir.glob("#{LIB_DIR}/distil/task/*-task.rb") { |file|
    require file
  }

end

