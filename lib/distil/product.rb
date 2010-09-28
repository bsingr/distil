module Distil
  
  class Product
    class_attr :content_type
    attr_reader :project
    
    def initialize(project)
      @project= project
    end

    def handles_file?(file)
      file.extension==content_type
    end

    def files
      @files unless @files.nil?
      
      @files= []
      project.ordered_files.each { |f|
        @files << f if handles_file?(f)
      }
      
      @files
    end
    
    def build_debug
    end
    
    def build_release
    end
    
    def minimise
    end
    
    def gzip
    end
    
  end
  
end

# load all the other file types
Dir.glob("#{Distil::LIB_DIR}/distil/product/*.rb") { |file|
  require file
}
