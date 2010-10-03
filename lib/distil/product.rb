module Distil
  
  RELEASE_VARIANT= :release
  DEBUG_VARIANT= :debug
  
  class Product
    class_attr :content_type
    class_attr :variants
    
    attr_reader :project, :files, :language, :variant, :assets

    def initialize(project, language, variant=nil)
      @project= project
      @language= language ? language.to_s : language
      @files= []
      @assets= Set.new
      @variant= variant
    end

    def filename
      filename= "#{project.name}"
      filename << "-#{language}" if language
      filename << "-#{variant}"
      filename << ".#{content_type}"
    end
    
    def output_path
      @output_path ||= File.join(project.output_path, filename)
    end
    
    def handles_file?(file)
      # puts "#{self.class}#handles_file: #{file} file-lang=#{file.language} prod-lang=#{language} equal=#{file.language==language}"
      return (file.extension==content_type) &&
             (language.nil? || file.language.nil? || file.language==language)
    end
  
    def include_file(file)
      return true if @files.include?(file)
      if file.is_a?(RemoteAsset)
        @files << file
        return true
      end
      
      if handles_file?(file)
        @files << file
        @assets.merge(file.assets) if file.assets
        return true
      end
    end
    
    def up_to_date?
      false
    end

    def build
      return if up_to_date?
      
      FileUtils.mkdir_p(File.dirname(output_path))
      self.send "build_#{variant}"
    end
    
    def minimise
      return unless variant==RELEASE_VARIANT
      build unless up_to_date?
      
    end
    
    def gzip
    end
    
    def build
      return if up_to_date?
    end
    
  end
  
end

# load all the other file types
Dir.glob("#{Distil::LIB_DIR}/distil/product/*.rb") { |file|
  require file
}
