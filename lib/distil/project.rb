module Distil
  
  BUILD_FILE= 'Buildfile'
  DEFAULT_OUTPUT_FOLDER= 'build'
  
  class Project < Configurable
    include ErrorReporter
    include FileVendor
    
    attr_reader :name, :path, :folder, :source_folder, :output_folder, :assets, :asset_aliases, :remote_assets, :include_paths
    alias_config_key :project_type, :type
    alias_config_key :source_files, :source
    alias_config_key :remote_assets, :require
    
    def self.default
      @default ||= find
    end
    
    def self.default=(env)
      @default = env
    end
    
    def self.find(dir=nil)
      dir ||= Dir.pwd
      while dir.length > 1
        candidates= [BUILD_FILE, "*.jsproj"]
        # candidates << BUILD_FILE.downcase unless File.identical?(BUILD_FILE, BUILD_FILE.downcase)
        
        projects= Dir.glob(File.join(dir, "{#{candidates.join(",")}}"))
        return new(projects.first) if 1==projects.size
        
        unless 0==projects.size
          puts "More than one candidate for Project:"
          projects.each { |e|
            puts "  #{path_relative_to_folder(e, cwd)}"
          }
          exit 1
        end
        
        dir= File.dirname(dir)
      end
      
      puts "Unable to find Project"
      exit 1
    end
    
    def initialize(env)
      @path= env
      @folder= File.dirname(@path)
      @source_folder= @folder
      Dir.chdir(@folder)
      @output_folder= DEFAULT_OUTPUT_FOLDER
      @include_paths= [@folder]
      @source_files= []
      @ordered_files= []
      @asset_aliases= {}
      @assets= Set.new
      @inspected_files= Set.new
      @remote_assets=[]
      @remote_assets_by_name={}
      yaml= YAML::load_file(@path)
      from_hash(yaml)
    end  

    def remote_assets=(assets)
      assets.each { |a|
        asset= RemoteAsset.new(a)
        asset.build
        @remote_assets << asset
        @remote_assets_by_name[asset.name]= asset
      }
    end
    
    def notice_text
      @notice_text ||= File.read(@notice)
    end
    
    def products
      @products unless @products.nil?
      
      @products= []
      Product.subclasses.each { |klass|
        p= klass.new(self)
        @products << p unless p.files.empty?
      }
      
      @products
    end
    
    def product_files
      @product_files unless @product_files.nil?
      @product_files= []
      products.each { |p| @product_files.concat(p.files) }
      @product_files.uniq!
      @product_files
    end
    
    def add_alias_for_asset(alias_name, asset)
      if asset_aliases.include?(alias_name)
        error "Attempt to register asset with the same alias as another asset: #{alias_name}"
        return
      end
      asset_aliases[alias_name]= asset
    end
    
    def source_files
      @source_files
    end

    def source_files=(set)
      @source_files=[]
      set= set.split(",").map { |f| f.strip } if set.is_a?(String)
      set.each { |f|
        add_source_file(f)
      }
    end
    
    def add_source_file(file)
      return if file.nil?
      
      if @remote_assets_by_name.include?(file)
        asset= @remote_assets_by_name[file]
        add_source_file asset.file_for(:js)
        add_source_file asset.file_for(:css)
        return
      end
      
      full_path= find_file(file)
      
      unless full_path.nil?
        if File.directory?(full_path)
          files= Dir.glob(File.join(full_path, "**/*")) { |f|
            add_source_file(f)
          }
        else
          f= file_from_path(full_path)
          @source_files << f unless @source_files.include?(f)
        end
        return
      end
      
      globbed= glob(file)
    
      if 0==globbed.length
        error("File not found #{file}")
        return
      end
      
      globbed.each { |f|
        f= file_from_path(f)
        @source_files << f unless @source_files.include?(f)
      }
    end
    
    def add_ordered_file(file)
      return if @ordered_files.include?(file)
      return unless @source_files.include?(file)
      return if @inspected_files.include?(file)
      
      @inspected_files << file
      file.dependencies.each { |d|
        add_ordered_file(d)
      }
      @assets.merge(file.assets)
      @ordered_files << file
    end
    
    def ordered_files
      @ordered_files unless @ordered_files.empty?
      source_files.each { |f|
        add_ordered_file(f)
      }
      @ordered_files
    end
        
    def glob(path)
      return path if File.exists?(path)
      
      files= []
      
      parts= path.split(File::SEPARATOR)
      asset_name= parts[0]
      file_path= File.join(parts.slice(1..-1))

      if (@remote_assets_by_name.include?(asset_name))
        asset= @remote_assets_by_name[asset_name]
        return Dir.glob(File.join(asset.include_path, file_path))
      end
      
      include_paths.each { |i|
        files.concat(Dir.glob(File.join(i, path)))
      }
      return files
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

      return nil unless @remote_assets_by_name.include?(asset_name)
      asset= @remote_assets_by_name[asset_name]
      
      return asset.file_for(content_type, mode) if 1==parts.length
      
      f= File.join(asset.include_path, file_path)
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
