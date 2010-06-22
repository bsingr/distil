module Distil
  
  class RemoteProject < Project

    option :name, String
    option :href, URI
    option :linkage, WEAK_LINKAGE, :valid_values=> [WEAK_LINKAGE, STRONG_LINKAGE, LAZY_LINKAGE]

    def initialize(config, parent=nil)

      super(config, parent)

      if !href.respond_to?(:read)
        raise ValidationError, "Cannot read from project source url: #{source}"
      end
      
      @source_path= File.join(parent.output_folder, href.host, href.path)
      self.source_folder=  File.dirname(@source_path)
      
      if !File.exist?(@source_path)
        FileUtils.mkdir_p(source_folder)
        text= href.read
        File.open(@source_path, "w") { |output|
          output.write text
        }
      end
      
    end

    def product_name(product_type, extension)
      File.join(File.dirname(@source_path), "#{File.basename(@source_path, ".*")}.#{extension}")
    end
    
    def build
    end
    
  end
  
end
