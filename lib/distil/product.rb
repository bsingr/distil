module Distil
  
  class Product < Configurable
    option :import_name, OutputPath, "$(name)-debug.$(extension)", :aliases=>['import']
    option :concatenated_name, OutputPath, "$(name)-uncompressed.$(extension)", :aliases=>['concatenated']
    option :debug_name, OutputPath, "$(name)-debug.$(extension)", :aliases=>['debug']
    option :minified_name, OutputPath, "$(name).$(extension)", :aliases=>['minified']
    option :compressed_name, OutputPath, "$(name).$(extension).gz", :aliases=>['compressed']

    option :include_files, FileSet, :aliases=>['include']
    option :exclude_files, FileSet, :aliases=>['exclude']

    option :validate, true
    option :generate_docs, false

    option :minify, true
    option :compress, true
    option :force, false
    
    attr_accessor :assets, :target, :join_string
    class_attr :extension
    class_attr :sort_order
    class_attr :config_key
    
    def initialize(settings, target)
      if settings.is_a?(Array)
        settings= {
          "include"=>settings,
          "exclude"=>[]
        }
      end

      @target= target
      @assets= Set.new
      @probed= Set.new
      @contents= {}
      @join_string= "\n"
      
      super(settings, target)
    end

    def tasks
      @tasks ||= Task.tasks.map { |task| task.new(@extras.clone, self) }
    end
    
    def handles_file?(file)
      false
    end
    
    def include_file(file)
      return if @probed.include?(file)
      return if @source_files.include?(file)
      return if !handles_file?(file)
      return if !include_files.include?(file)
      return if exclude_files.include?(file)

      @probed << file

      tasks.each { |task| task.include_file(file) }
      
      file.dependencies.each { |d| include_file(d) }
      @assets.merge(file.assets)
      @assets << file
      @source_files << file
    end
    
    def source_files
      return @source_files if @source_files
      
      @probed= Set.new
      @source_files= []
    
      include_files.each { |i| include_file(i) }
      @source_files
    end

    def output_files
      return @output_files if @output_files
      
      @output_files= []
      tasks.each { |task| 
        @output_files.concat(task.products)
      }
      @output_files
    end
    
    def validate_files
      return if (!validate)
      tasks.each { |task| task.validate_files(source_files) }
    end

    def document_files
      return if (!generate_docs)
      tasks.each { |task| task.document_files(source_files) }
    end
    
    def process_files
      tasks.each { |task| task.process_files(source_files) }
    end

    def symlink_assets
      folders= []

      assets.each { |a|
        path= a.file_path || a.relative_to_folder(source_folder)

        parts= File.dirname(path).split(File::SEPARATOR)
        if ('.'==parts[0])
          product_path= File.join(output_folder, path)
          FileUtils.rm product_path if File.exists? product_path
          File.symlink a.relative_to_folder(output_folder), product_path
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
        product_folder= File.join(project.output_folder, f)
        
        next if File.exists?(product_folder)
        File.symlink src_folder, product_folder
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
      
      product_mtimes= output_files.map { |p|
        p=File.expand_path(p)
        return (@need_to_build=true) if !File.exists?(p)
        File.stat(p).mtime
      }

      asset_mtimes= assets.map { |f| File.stat(f).mtime }
      asset_mtimes << File.stat(project.project_file).mtime
      
      return (@need_to_build=false) if 0==product_mtimes.length
        
      @need_to_build= (asset_mtimes.max > product_mtimes.min)
    end

    def concatenate_files

      File.open(concatenated_name, "w") { |f|
        f.write(target.notice_text)
        concat_files.each { |file|
          f.write(join_string)
          f.write(target.get_content_for_file(file))
        }
      }
      
    end
    
    def build
      return if !need_to_build
      
      validate_files
      document_files
      process_files
      build_assets

      concatenate_files
      minify_product
    end

    def find_file(file)
      @target.project.find_file(file)
    end

    def minify_product
      FileUtils.cp concatenated_name, minified_name
    end
    
    def source_folder
      target.project.source_folder
    end
    
    @@product_config_key_index= nil
    @@product_types= []
    def self.inherited(subclass)
      @@product_types << subclass
    end

    def self.product_types
      @@product_types
    end

    def self.from_config_key(key)
      if !@@product_config_key_index
        @@product_config_key_index= {}
        @@product_types.each { |target|
          @@product_config_key_index[target.config_key]= target
        }
      end
      
      @@product_config_key_index[key]
    end

  end
  
end

Dir.glob("#{File.dirname(__FILE__)}/product/*-product.rb") { |file|
  require file
}
