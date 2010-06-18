module Distil

  class Target < Configurable
    include ErrorReporter
    
    attr_accessor :project, :assets
    
    option :version, String
    option :name, String
    option :notice_file, ProjectPath, "$(source_folder)/NOTICE", :aliases=>['notice']
    option :target_type, String, FRAMEWORK_TYPE, :aliases=>['type'], :valid_values=>[FRAMEWORK_TYPE, APP_TYPE]

    option :include_files, FileSet, :aliases=>['source']
    option :exclude_files, FileSet, :aliases=>['exclude']

    option :include_projects, [], :aliases=>['include']
    
    option :validate, true
    option :generate_docs, false

    option :minify, true
    option :compress, true

    option :global_export, :aliases=>['export']

    def initialize(settings, project)
      @project=project

      super(settings, project)

      @assets= Set.new
      @probed= Set.new
      @contents= {}
      @asset_aliases= {}
      
      if !include_files
        self.include_files= FileSet.new
      end
      
      if !exclude_files
        self.exclude_files= FileSet.new
      end

      @options.global_export=name if true==global_export

      include_projects.each { |p|
        external_project= project.external_project_with_name(p)
        if !external_project
          raise ValidationError.new("No such external project: #{p}")
        end
        
        if (WEAK_LINKAGE==external_project.linkage)
          external_project.linkage= STRONG_LINKAGE
        end
      }
    end

    def source_folder
      project.source_folder
    end
    
    def tasks
      @tasks ||= Task.tasks.map { |task| task.new(@extras.clone, self) }
    end

    def products
      return @products if @products
      
      product_types= [CssProduct, CssDebugProduct, JavascriptProduct, JavascriptDebugProduct]
      if minify
        product_types << CssMinifiedProduct
        product_types << JavascriptMinifiedProduct
      end

      if generate_docs
        product_types << JavascriptDocProduct
      end
      
      @products=[]
      product_types.each { |t|
        product= t.new(@extras.clone, self)
        product.files= files
        @products << product if !product.files.empty?
      }

      if APP_TYPE==target_type
        product= PageProduct.new(@extras.clone, self)
        product.files= files
        @products << product if !product.files.empty?
      end
      
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

    def include_file(file)
      return if @probed.include?(file)
      return if @files.include?(file)
      return if !include_files.include?(file)
      return if exclude_files.include?(file)

      @probed << file

      tasks.each { |t| t.include_file(file) }
      
      file.dependencies.each { |d| include_file(d) }
      @assets.merge(file.assets)
      @assets << file
      @files << file
    end
    
    def files
      return @files if @files
      
      @probed= Set.new
      @files= []
    
      tasks.each { |t|
        extra_files= t.find_files
        extra_files.each { |f| include_files.include_file(f) }
      }
      
      include_files.each { |i| include_file(i) }
      
      @files
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
    
    def add_asset(asset)
      @assets << asset
    end
    
    def set_alias_for_asset(asset_alias, asset_file)
      @assets << asset_file
      @asset_aliases[asset_file.to_s]= asset_alias
    end
    
    def alias_for_asset(asset_file)
      full_path= asset_file.to_s
      @asset_aliases[full_path] || asset_file.relative_to_folder(source_folder)
    end
    
    def up_to_date
      products.all? { |p| p.up_to_date }
    end
    
    def build
      puts "\n#{name}:\n\n"
      
      tasks.each { |t| t.process_files(files) }
      
      products.each { |p| p.write_output }
      
      build_assets
    end
    
    def find_file(file, source_file=nil)
      return nil if project.external_projects.nil?
      
      parts= file.split(File::SEPARATOR)
      project_name= parts[0]

      external_project= project.external_project_with_name(project_name)
      return nil if !external_project

      if 1==parts.length
        return SourceFile::from_path(external_project.product_name(:import, source_file.extension))
      else
        return SourceFile::from_path(File.join(external_project.source_folder, *parts[1..-1]))
      end
    end
    
    def get_content_for_file(file)
      file=SourceFile.from_path(file) if !file.is_a?(SourceFile)
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
