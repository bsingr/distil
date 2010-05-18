module Distil

  class Target < Configurable
    include ErrorReporter
    
    class_attr :config_key, :sort_order
    attr_accessor :assets, :files, :products, :project
    
    option :include_files, FileSet, :aliases=>['include']
    option :exclude_files, FileSet, :aliases=>['exclude']
    option :validate, true
    option :generate_docs, false
    option :product_extension
    option :notice_file, ProjectPath, "$(source_folder)/NOTICE", :aliases=>['notice']
    option :force, false
    
    def initialize(settings, project)
      if settings.is_a?(Array)
        settings= {
          "include"=>settings,
          "exclude"=>[]
        }
      end

      @project=project
      @assets= Set.new
      @probed= Set.new
      @contents= {}
      @files= []
      @products= []
      
      super(settings, project)
    end

    def tasks
      @tasks ||= Task.tasks.map { |task| task.new(self) }
    end
    
    def handles_file?(file)
      false
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
    
    def include_file(file)
      return if @probed.include?(file)
      return if @files.include?(file)
      return if !handles_file?(file)
      return if !include_files.include?(file)
      return if exclude_files.include?(file)

      @probed << file

      tasks.each { |task| task.include_file(file) }
      
      file.dependencies.each { |d| include_file(d) }
      @assets.merge(file.assets)
      @assets << file
      @files << file
      
    end

    def find_files
      @probed= Set.new
      @files= []
    
      include_files.each { |i| include_file(i) }
    end

    def collect_products
      @products= []
      tasks.each { |task| 
        @products.concat(task.products)
      }
    end
    
    def validate_files
      return if (!validate)
      tasks.each { |task| task.validate_files(files) }
    end

    def document_files
      return if (!generate_docs)
      tasks.each { |task| task.document_files(files) }
    end
    
    def process_files
      tasks.each { |task| task.process_files(files) }
    end

    def symlink_assets
      folders= []

      assets.each { |a|
        path= a.file_path || a.relative_to_folder(source_folder)

        parts= File.dirname(path).split(File::SEPARATOR)
        if ('.'==parts[0])
          target_path= File.join(output_folder, path)
          FileUtils.rm target_path if File.exists? target_path
          File.symlink a.relative_to_folder(output_folder), target_path
          next
        end

        for i in (0..parts.length-1)
          f= parts[0..i].join(File::SEPARATOR)
          if !folders.include?(f)
            folders << f
          end
        end
      
      }
    
      folders.sort!
      
      folders.each { |f|
        src_folder= File.join(source_folder, f)
        target_folder= File.join(project.output_folder, f)
        
        next if File.exists?(target_folder)
        File.symlink src_folder, target_folder
      }
    end
  
    def copy_assets
      assets.each { |a|
        a.copy_to(project.output_folder, source_folder)
      }
    end
  
    def build_assets
      if (RELEASE_MODE==project.mode)
        copy_assets
      else
        symlink_assets
      end
    end
    
    def need_to_build
      return @need_to_build if !@need_to_build.nil?
      return true if force
      
      product_mtimes= @products.map { |p|
        p=File.expand_path(p)
        return (@need_to_build=true) if !File.exists?(p)
        File.stat(p).mtime
      }

      asset_mtimes= assets.map { |f| File.stat(f).mtime }
      asset_mtimes << File.stat(project.project_file).mtime
      
      return (@need_to_build=false) if 0==product_mtimes.length
        
      @need_to_build= (asset_mtimes.max > product_mtimes.min)
    end
    
    def build
      find_files
      collect_products

      return if !need_to_build
      
      validate_files
      document_files
      process_files
      build_assets
    end
    
    @@target_config_key_index= nil
    @@target_types= []
    def self.inherited(subclass)
      @@target_types << subclass
    end

    def self.target_types
      @@target_types
    end

    def self.from_config_key(key)
      if !@@target_config_key_index
        @@target_config_key_index= {}
        @@target_types.each { |target|
          @@target_config_key_index[target.config_key]= target
        }
      end
      
      @@target_config_key_index[key]
    end

    def source_folder
      @project.source_folder
    end

    def find_file(file)
      @project.find_file(file)
    end
    
    def get_debug_reference_for_file(file)
      "\"#{file.relative_to_folder(source_folder)}\""
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
Dir.glob("#{File.dirname(__FILE__)}/target/*-target.rb") { |file|
  require file
}
