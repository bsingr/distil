require 'fileutils'

module Distil

  class SourceFile
    attr_reader :full_path, :project
    attr_accessor :language, :is_asset
    
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
    
    def output_path
      # SourceFiles get copied (or symlinked) into the output folder so that
      # their path is the same as that relative to the source folder
      @output_path||= File.join(project.output_path, relative_path)
    end
    
    def relative_path
      return @relative_path if @relative_path
      if full_path.starts_with?(project.output_path)
        @relative_path= Project.path_relative_to_folder(full_path, project.output_path)
      else
        @relative_path=Project.path_relative_to_folder(full_path, project.source_path)
      end
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

    def rewrite_content_relative_to_path(path)
      content
    end
    
    def last_modified
      @last_modified ||= File.stat(@full_path).mtime
    end
    
    def minified_content(source=content)
      return source
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
      file.is_asset=true
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
require 'distil/source-file/yui-minifiable-file'
require 'distil/source-file/css-file'
require 'distil/source-file/html-file'
require 'distil/source-file/javascript-file'
require 'distil/source-file/json-file'
