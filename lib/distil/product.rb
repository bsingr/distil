module Distil
  
  class Product < Configurable
    option :concatenated_name, OutputPath, "$(name)-uncompressed.$(extension)", :aliases=>['concatenated']
    option :debug_name, OutputPath, "$(name)-debug.$(extension)", :aliases=>['debug']
    option :minified_name, OutputPath, "$(name).$(extension)", :aliases=>['minified']
    option :compressed_name, OutputPath, "$(name).$(extension).gz", :aliases=>['compressed']

    option :force, false
    
    attr_accessor :assets, :target, :join_string
    class_attr :extension
    
    def initialize(settings, target)
      @target= target
      @files= []
      @assets= Set.new
      super(settings, target)
    end

    def can_embed_file?(file)
      false
    end
    
    def handles_file?(file)
      [extension].include?(file.extension)
    end
    
    def files
      @files
    end
    
    def files=(fileset)
      fileset.each { |f|
        next if !handles_file?(f)
        @files << f
        @assets.merge(f.assets)
      }
    end
    
    def up_to_date
      return @up_to_date if !@up_to_date.nil?
      return false if force
      
      return @up_to_date=false if !File.exists?(filename)
      
      output_modified= File.stat(filename).mtime
      max_asset_modified= File.stat(target.project.project_file).mtime

      assets.each { |f|
        max_asset_modified= f.last_modified if f.last_modified > max_asset_modified
      }
      files.each { |f|
        max_asset_modified= f.last_modified if f.last_modified > max_asset_modified
      }

      return @up_to_date=false if (output_modified < max_asset_modified)
      
      external_files.each { |f|
        next if !File.exist?(f)
        last_modified= File.stat(f).mtime
        max_asset_modified= last_modified if last_modified > max_asset_modified
      }

      return @up_to_date=false if (output_modified < max_asset_modified)

      @up_to_date= true
    end

    def filename
      raise NotImplementedError.new("This product does not implement the filename method.")
    end
    
    def write_output
      raise NotImplementedError.new("No write_output method has been defined for this product.")
    end
    
    def relative_path(file)
      file=SourceFile.from_path(file) if file.is_a?(String)
      
      file_path= file.full_path
      output_folder= target.project.output_folder
      source_folder= target.project.source_folder
      
      path=file.relative_to_folder(source_folder) if 0==file_path.index(source_folder)
      path=file.relative_to_folder(output_folder) if 0==file_path.index(output_folder)
      path
    end

  end
  
end

require 'distil/product/concatenated'
require 'distil/product/debug'
require 'distil/product/minified'
require 'distil/product/css-product'
require 'distil/product/javascript-base-product'
require 'distil/product/javascript-product'
require 'distil/product/javascript-doc-product'
require 'distil/product/page-product'
