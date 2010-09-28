require 'fileutils'

module Distil

  class SourceFile
    attr_accessor :full_path, :project
    class_attr :extension
    class_attr :content_type
    
    include ErrorReporter
    
    def initialize(filepath, project)
      @full_path= File.expand_path(filepath)
      @project= project
      project.cache_file(self)
    end

    def warning(message, line=nil)
      super(message, self, line)
    end
    
    def error(message, line=nil)
      super(message, self, line)
    end
    
    def self.file_types
      self.subclasses
    end

    def relative_path
      Project.path_relative_to_folder(full_path, project.folder)
    end
    
    def path_relative_to(path)
      Project.path_relative_to_folder(full_path, path)
    end
    
    def to_s
      @full_path
    end
  
    def to_str
      @full_path
    end

    def dirname
      File.dirname(@full_path)
    end
    
    def basename(suffix="")
      File.basename(@full_path, suffix)
    end

    def extension
      @extension || self.class.extension || File.extname(full_path)[1..-1]
    end

    def content_type
      @content_type || self.class.content_type || File.extname(full_path)[1..-1]
    end

    def content
      @content ||= File.read(full_path)
    end

    def last_modified
      @last_modified ||= File.stat(@full_path).mtime
    end
    
    def minified_content(source=content)
    	# Run the Y!UI Compressor
      return source if !content_type
    	buffer= ""
    
    	IO.popen("java -jar #{COMPRESSOR} --type #{content_type}", "r+") { |pipe|
    	  pipe.puts(source)
    	  pipe.close_write
    	  buffer= pipe.read
  	  }
	  
      buffer
    end
  
    def path_relative_to_folder(folder)
      Project.path_relative_to_folder(@full_path, folder)
    end

    def dependencies
      @dependencies||=[]
    end

    def add_dependency(file)
      return if @dependencies.include?(file)
      @dependencies << file
    end
  
    def assets
      @assets||=Set.new
    end
  
    def add_asset(file)
      assets << file
    end
  
    def copy_to(folder, prefix)
      file_path= self.file_path || relative_to_folder(prefix||"")
      final_target_folder= File.join(folder, File.dirname(file_path))
      FileUtils.mkdir_p final_target_folder
      FileUtils.cp self.full_path, final_target_folder
      File.join(final_target_folder, File.basename(file_path))
    end
  
  end

end

# load all the other file types
Dir.glob("#{Distil::LIB_DIR}/distil/source-file/*-file.rb") { |file|
  require file
}
