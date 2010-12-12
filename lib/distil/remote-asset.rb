module Distil
  
  REMOTE_ASSET_CACHE_FOLDER= File.expand_path("~/.distil/asset_cache")
  
  class RemoteAsset < Configurable

    attr_reader :name, :path, :href, :version, :include_path, :project
    attr_reader :build_command, :revision, :protocol

    def initialize(config, project)
      @project= project
      
      if config.is_a?(String)
        config= {
          :href=>config
        }
      end

      configure_with(config) do |c|
        
        c.with :href do |href|
          @href= URI.parse(href)
          case when svn_url?
            @protocol= :svn
          when git_url?
            @protocol= :git
          when http_folder?
            @protocol= :http_recursive
          else
            @protocol= :http
          end
        end
        
      end
      
      @name ||= File.basename(href.path, ".*")

      if @path.nil?
        parts= [REMOTE_ASSET_CACHE_FOLDER, href.host, File.dirname(href.path)]
        case when svn_url? || git_url?
          parts << File.basename(href.path, ".*")
        when http_folder?
          parts << File.basename(href.path)
        end
        @path= File.join(*parts)
        @path << "-#{@version}" unless @version.nil?
      end
      
      @path= File.expand_path(@path)

      Dir.chdir(path) do
        case
        when File.exist?("Buildfile") || File.exists?("buildfile") || File.exist?("#{name}.jsproj")
          @build_command= APP_SCRIPT
          remote_project= Project.find(path)
          output_folder= remote_project ? remote_project.output_folder : 'build'
          @product_path= File.join(path, output_folder)
        when File.exist?("Makefile") || File.exist?("makefile")
          @build_command= "make"
        when File.exists?("Rakefile") || File.exists?("rakefile")
          @build_command= "rake"
        when File.exists?("Jakefile") || File.exists?("jakefile")
          @build_command= "jake"
        else
          @build_command= ""
        end
      end
      
      build
    end

    def to_s
      "RemoteAsset: #{name} @ #{path}"
    end

    def dependencies
      []
    end
    
    def assets
      nil
    end
    
    def include_path
      File.join(path, @include_path||"")
    end
    
    def product_path
      @product_path || path
    end
    
    def svn_url?
      "#{@href}" =~ /svn(?:\+ssh)?:\/\/*/
    end
  
    def git_url?
      "#{@href}" =~ /^git:\/\// || "#{@href}" =~ /\.git$/
    end
    
    def http_folder?
      File.extname(href.path).empty?
    end

    def require_git
      begin
        `git --version 2>/dev/null`
      rescue
        nil
      end
      if $?.nil? || !$?.success?
        raise ValidationError.new("The git version control tool is required to pull this repository: #{uri}")
      end
    end
    
    def fetch_with_git
      require_git
      FileUtils.mkdir_p(path)
      Dir.chdir path do
        clone_cmd  = "git clone"
        clone_cmd += " -b #{version}" unless version.nil?
        clone_cmd += " #{href} ."
        clone_cmd += " -q"
        if !system(clone_cmd)
          raise ValidationError.new("Failed to clone external project: #{href}")
        end
      end          
    end

    def fetch_with_http
      if !href.respond_to?(:read)
        raise ValidationError, "Cannot read from project source url: #{href}"
      end

      FileUtils.mkdir_p(path)
      begin
        text= href.read
      rescue OpenURI::HTTPError => http_error
        raise ValidationError, "Unable to fetch remote project: status=#{http_error.io.status[0]} url=#{href}"
      end
      File.open(File.join(path, File.basename(href.path)), "w") { |output|
        output.write text
      }
    end

    def fetch_with_http_recursive
      dir= File.dirname(path)
      FileUtils.mkdir_p(dir)
      fetcher= Distil::RecursiveHTTPFetcher.new(href, 1, dir)
      fetcher.fetch
    end
    
    def fetch
      self.send "fetch_with_#{@protocol}"
    end
    
    def update_with_git
      require_git
      Dir.chdir path do
        `git pull`
      end
    end
    
    def update_with_http
      fetch_with_http
    end
    
    def update
      if File.exists?(path)
        self.send "update_with_#{@protocol}"
      else
        fetch
      end
    end
    
    def output_path
      @output_path||= File.join(project.output_path, name)
    end
    
    def up_to_date?
      return false unless File.exists?(path)
      case protocol
      when :git
        require_git
        revision==`git rev-parse #{version}`
      else
        true
      end
    end
    
    def build
      # update unless up_to_date?

      command= build_command
      return if command.empty?
      
      Dir.chdir(path) do
        exit 1 if !system("#{command}")
      end
      
      File.unlink(output_path) if File.symlink?(output_path)
      
      # FileUtils.rm_rf(project_path) if File.directory?(project_path)
      File.symlink(project.relative_output_path_for(product_path), output_path)
    end
    
    def content_for(content_type, variant=RELEASE_VARIANT)
      file= file_for(content_type, variant)
      return nil if !file
      File.read(file)
    end
    
    def file_for(content_type, variant=RELEASE_VARIANT)
      file= File.join(output_path, "#{name}-#{variant}.#{content_type}")
      return file if File.exists?(file)
      file= File.join(output_path, "#{name}-uncompressed.#{content_type}")
      return file if File.exists?(file)
      file= File.join(output_path, "#{name}.#{content_type}")
      return file if File.exists?(file)
      
      candidates= Dir.glob(File.join(output_path, "*.#{content_type}"))
      return candidates.first if 1==candidates.length
      
      nil
    end

  end
  
end
