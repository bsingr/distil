module Distil
  
  BUILD_FILE= 'Buildfile'
  DEFAULT_OUTPUT_FOLDER= 'build'
  DEFAULT_LANGUAGE= 'en'

  APPLICATION_TYPE= 'application'
  FRAMEWORK_TYPE= 'framework'
  
  class Project < Configurable
    include ErrorReporter
    include FileVendor
    include JavascriptFileValidator
    
    attr_reader :name, :path, :folder, :source_folder, :output_folder, :include_paths
    attr_reader :assets, :asset_aliases
    attr_reader :libraries_by_name, :libraries
    attr_reader :languages, :project_type
    attr_reader :source_files
    attr_reader :global_export
    attr_reader :additional_globals
    attr_reader :subprojects
    attr_reader :dependency_aliases
    
    alias_config_key :project_type, :type

    def self.find(dir=nil)
      cwd= Dir.pwd
      dir ||= Dir.pwd
      while dir.length > 1
        return from_file(File.join(dir, BUILD_FILE)) if File.exists?(File.join(dir, BUILD_FILE))
        
        projects= Dir.glob(File.join(dir, "*.jsproj"))
        return from_file(projects.first) if 1==projects.size
        
        unless 0==projects.size
          puts "More than one candidate for Project:"
          projects.each { |e|
            puts "  #{path_relative_to_folder(e, cwd)}"
          }
          exit 1
        end
        
        dir= File.dirname(dir)
      end
      
      nil
    end
    
    def self.from_file(file)
      yaml= YAML::load_file(file)
      if File.exists?("#{file}.local")
        local_yaml= YAML::load_file("#{file}.local")
        yaml.deep_merge!(local_yaml)
      end
      new(file, yaml)
    end
    
    def initialize(path, config={}, parent=nil)
      @path= path
      @folder= File.dirname(@path)
      @source_folder= @folder
      @output_folder= DEFAULT_OUTPUT_FOLDER
      @include_paths= [@folder]
      @include_files= []
      @asset_aliases= {}
      @dependency_aliases= {}
      @assets= Set.new
      @source_files= Set.new
      @subprojects= []
      @libraries= parent ? parent.libraries : []
      @libraries_by_name= parent ? parent.libraries_by_name : {}
      @languages= []
      @additional_globals= []
      @name= File.basename(@folder, ".*")
      
      ignore_warnings= false

      child_config= config.dup
      child_config.delete("targets")
      child_config.delete("require")
      
      Dir.chdir(@folder) do
        configure_with config do |c|

          c.with :name do |name|
            @name= name
          end
          
          c.with :output_folder do |output_folder|
            @output_folder= output_folder
          end
          FileUtils.mkdir_p output_folder
          
          c.with :source_folder do |source_folder|
            @source_folder= source_folder
          end

          c.with :export do |export|
            export=@name.as_identifier if true==export
            @global_export= export
          end
          
          c.with_each :globals do |global|
            @additional_globals << global
          end
          
          c.with_each :languages do |language|
            @languages << language
          end
          
          c.with_each :require do |asset|
            asset= Library.new(asset, self)
            @libraries << asset
            @libraries_by_name[asset.name]= asset
          end

          c.with_each :source do |file|
            include_file(file)
          end
        
          c.with_each :targets do |target|
            target_config= child_config.dup
            target_config.deep_merge!(target)
            @subprojects << Project.new(path, target_config, self)
          end
          
        end # configure_with
      end
    
    end  

    def validate_files
      validate_javascript_files
    end

    def compute_source_files
      return if @source_files_computed
      @source_files_computed= true
      
      inspected= Set.new
      ordered_files= []
    
      add_file= lambda { |f|
        return unless include_files.include?(f)
        return if inspected.include?(f)
        inspected << f
        
        if f.respond_to? :dependencies
          f.dependencies.each { |d|
            add_file.call d
          }
        end
        
        ordered_files << f
      }
    
      include_files.each { |f| add_file.call(f) }
      ordered_files.each { |f|
        next if f.is_a?(SourceFile) && f.is_asset
        
        used= false
        products.each { |p|
          used= true if p.include_file(f)
        }
        
        next if !used
        
        if !f.is_a?(Library)
          @source_files << f
          @assets.merge(f.assets) if f.assets
        end
      }
    end
    
    def up_to_date?
      products.each { |product|
        return false if !product.up_to_date?
      }
      return true
    end
    
    def build
      subprojects.each { |subproject|
        subproject.build
      }

      compute_source_files
      return if up_to_date?
      
      validate_files
      build_assets
      
      products.each { |product|
        product.build
      }
    end
    
    def clean
      compute_source_files
      products.each { |product|
        product.clean
      }
    end
    
    def inspect
      "<#{self.class}:0x#{object_id.to_s(16)} name=#{name}>"
    end
    
    def output_path
      @output_path ||= File.join(folder, output_folder)
    end
    
    def relative_path_for(thing)
      Project.path_relative_to_folder(thing.is_a?(String) ? thing : thing.full_path, path)
    end
    
    def relative_output_path_for(thing)
      return nil if !thing
      # puts "relative_output_path_for: #{thing} #{output_path}"
      Project.path_relative_to_folder(thing.is_a?(String) ? thing : thing.output_path, output_path)
    end
    
    def notice_text
      begin
        @notice_text ||= File.read(File.join(@folder, @notice)).strip
      rescue
        @notice_text ||= ""
      end
    end
    
    def products
      return @products unless @products.nil?
      
      @products= []
      langs= languages.empty? ? [nil] : languages
      
      Product.subclasses.each { |klass|
        langs.each { |lang|
          klass.variants.each { |v|
            @products << klass.new(self, lang, v)
          }
        }
      }
      
      @products
    end
    
    def symlink_assets
      Dir.chdir(output_path) do
        folders= []

        files= assets+source_files
        files.each { |a|
          next if (a.full_path).starts_with?(output_path)

          path= relative_output_path_for(a)

          parts= File.dirname(path).split(File::SEPARATOR)
          if ('.'==parts[0])
            product_path= File.join(output_folder, path)
            FileUtils.rm product_path if File.exists? product_path
            File.symlink path, product_path
            next
          end

          folders << parts[0] if !folders.include?(parts[0])
        }
    
        folders.each { |f|
          target= f
          source= relative_output_path_for(File.join(source_folder, f))

          FileUtils.rm target if File.symlink?(target)
          next if File.directory?(target)
          File.symlink source, target
        }
      end
    end
  
    def copy_assets
      assets.each { |a|
        a.copy_to(output_folder, source_folder)
      }
    end
  
    def build_assets
      symlink_assets
      # if (RELEASE_MODE==mode)
      #   copy_assets
      # else
      #   symlink_assets
      # end
    end
    
    def add_alias_for_asset(alias_name, asset)
      if asset_aliases.include?(alias_name)
        error "Attempt to register asset with the same alias as another asset: #{alias_name}"
        return
      end
      asset_aliases[asset]= alias_name
    end
    
    def include_files
      @include_files
    end

    def include_file(file)
      return if file.nil?
      
      asset= @libraries_by_name[file]
      if (asset)
        @include_files << asset unless @include_files.include?(asset)
        return
      end
      
      matches= glob(file)
      matches= glob(File.join(source_folder, file)) if matches.empty?
      
      if (matches.empty?)
        error("No matching files found for: #{file}")
        return
      end
      
      matches.each { |m|
        if File.directory?(m)
          include_file(File.join(m, "**/*"))
        else
          f= file_from_path(m)
          unless @include_files.include?(f)
            @include_files << f
            # determine language
            f.language= languages.find { |l| File.fnmatch?("**/#{l}/**", f.full_path) }
          end
        end
      }
    end
    
    def glob(path)
      return path if File.exists?(path)
      
      files= []
      
      parts= path.split(File::SEPARATOR)
      asset_name= parts[0]
      file_path= File.join(parts.slice(1..-1))

      if (@libraries_by_name.include?(asset_name))
        asset= @libraries_by_name[asset_name]
        return Dir.glob(File.join(asset.output_path, file_path))
      end
      
      files.concat(Dir.glob(path));
      
      include_paths.each { |i|
        files.concat(Dir.glob(File.join(i, path)))
      }
      return files
    end
    
    def add_alias_for_file(alias_name, file)
      @dependency_aliases[alias_name]= file
    end
        
    def find_file(path, content_type=nil, mode=nil)
      return path if File.exists?(path)
      
      include_paths.each { |i|
        f= File.join(i, path)
        return f if File.exists?(f)
      }
      
      # Check remote assets
      parts= path.split(File::SEPARATOR)
      asset_name= parts[0]
      file_path= File.join(parts.slice(1..-1))

      return nil unless @libraries_by_name.include?(asset_name)
      asset= @libraries_by_name[asset_name]
      
      return asset.file_for(content_type, nil, mode) if 1==parts.length
      
      f= File.join(asset.output_path, file_path)
      return f if File.exists?(f)
      
      nil
    end
    
    def self.path_relative_to_folder(path, folder)
      path= File.expand_path(path)
      outputFolder= File.expand_path(folder).to_s
  
      # Remove leading slash and split into parts
      file_parts= path.slice(1..-1).split('/');
      output_parts= outputFolder.slice(1..-1).split('/');

      common_prefix_length= 0

      file_parts.each_index { |i|
        common_prefix_length= i
        break if file_parts[i]!=output_parts[i]
      }

      return '../'*(output_parts.length-common_prefix_length) + file_parts[common_prefix_length..-1].join('/')
    end
    
  end
  
  
end
