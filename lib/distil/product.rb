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

    def notice_comment
      return @notice_comment if @notice_comment
      notice_text= project.notice_text
      return @notice_command= "" if !notice_text || notice_text.empty?
      
      @notice_comment=  "/*!\n    "
      @notice_comment<< project.notice_text.split("\n").join("\n    ")
      @notice_comment<< "\n */\n"
    end
    
    def filename
      filename= "#{project.name}"
      filename << "-#{language}" if language
      filename << "-#{variant}" if variants.length>1
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
        if file.file_for(content_type, variant)
          @files << file
          return true
        else
          return false
        end
      end
      
      if handles_file?(file)
        @files << file
        @assets.merge(file.assets) if file.assets
        return true
      end
    end
    
    def up_to_date?
      return false unless File.exists?(output_path)
      product_last_modified= File.stat(output_path).mtime
      files.each { |f|
        if f.is_a?(RemoteAsset)
          remote_asset= f.file_for(content_type, variant)
          return false if remote_asset && File.stat(remote_asset).mtime > product_last_modified
        else
          return false if f.last_modified > product_last_modified
        end
      }
      true
    end

    def build
      return if files.empty? || up_to_date?
      
      FileUtils.mkdir_p(File.dirname(output_path))
      self.send "build_#{variant}"
      minimise
      gzip
    end
    
    def clean
      FileUtils.rm output_path if File.exists?(output_path)
      return unless RELEASE_VARIANT==variant
      FileUtils.rm minimised_filename if File.exists?(minimised_filename)
      FileUtils.rm gzip_filename if File.exists?(gzip_filename)
    end

    def minimised_filename
      @minimised_filename if @minimised_filename
      
      minimised_filename= "#{project.name}"
      minimised_filename << "-#{language}" if language
      minimised_filename << ".#{content_type}"
      @minimised_filename= File.join(project.output_path, minimised_filename)
    end
    
    def minimise
      return unless RELEASE_VARIANT==variant
      system("java -jar #{COMPRESSOR} --type #{content_type} -o #{minimised_filename} #{output_path}")
    end
    
    def gzip_filename
      @gzip_filename ||= "#{minimised_filename}.gz"
    end
    
    def gzip
      return unless RELEASE_VARIANT==variant
      Zlib::GzipWriter.open(gzip_filename) do |gz|
        gz.write File.read(minimised_filename)
      end
    end
    
  end
  
end

# load all the other file types
Dir.glob("#{Distil::LIB_DIR}/distil/product/*.rb") { |file|
  require file
}
