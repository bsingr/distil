module Distil

  class Target < Configurable
    include ErrorReporter
    
    attr_accessor :project
    
    option :notice_file, ProjectPath, "$(source_folder)/NOTICE", :aliases=>['notice']
    
    def initialize(settings, project)
      @project=project
      
      super(settings, project)
    end

    def products
      return @products if @products
      
      @products=[]
      @extras.each { |key, value|
        product= Product.from_config_key(key)
        next if !product
        @products << product.new(value, self)
      }
      
      @products.sort! { |a, b| a.sort_order<=>b.sort_order }
      
      @products
    end
    
    def notice_text
      @notice_text if @notice_text

      if (nil==@notice_text)
        if (!File.exists?(notice_file))
          @notice_text= ""
        else
          text= File.read(notice_file).strip
          text= "    #{text}".gsub(/\n/, "\n    ")
          @notice_text= "/*!\n#{text}\n*/\n\n"
        end
      end
    end
    
    def build
      products.each { |p| p.build }
    end
    
    def find_file(file)
      @project.find_file(file)
    end
    
    def get_content_for_file(file)
      @contents[file.to_s] ||= file.content
    end

    def set_content_for_file(file, content)
      @contents[file.to_s] = content
    end
    
  end
  
end

# load all the other target types
# Dir.glob("#{File.dirname(__FILE__)}/target/*-target.rb") { |file|
#   require file
# }
