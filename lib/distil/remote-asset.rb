require 'uri'

module Distil
  
  REMOTE_ASSET_CACHE_FOLDER= File.expand_path("~/.distil/asset_cache")
  
  class RemoteAsset < Configurable

    attr_accessor :name, :href, :version, :include_path

    def initialize(config)
      if config.is_a?(String)
        config= {
          :href=>config
        }
      end
      from_hash(config)
      @name ||= File.basename(href.path, ".*")
    end

    def href=(new_href)
      @href= URI.parse(new_href)
      @cache_folder= nil
      case
        when svn_url?
          @protocol= 'svn'
        when git_url?
          @protocol= 'git'
        when http_folder?
          @protocol= 'http_recursive'
        else
          @protocol= 'http'
        end
      @href
    end
    
    def version=(new_version)
      @version= new_version
      @cache_folder= nil
    end
    
    def include_path
      File.join(cache_folder, @include_path||"")
    end
    
    def cache_folder
      @cache_folder unless @cache_folder.nil?
      
      parts= [REMOTE_ASSET_CACHE_FOLDER, href.host, File.dirname(href.path)]
      case
        when svn_url? || git_url?
          parts << File.basename(href.path, ".*")
        when http_folder?
          parts << File.basename(href.path)
        end
      @cache_folder= File.join(*parts)
      @cache_folder << "-#{@version}" unless @version.nil?
      @cache_folder
    end
    
    def build_command
      @build_command unless @build_command.nil?
      
      Dir.chdir(cache_folder) do
        case
        when File.exist?("Buildfile") || File.exists?("buildfile") || File.exist?("#{name}.jsproj")
          @build_command= "distil"
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
      
      @build_command
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

    def ensure_git
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
      ensure_git
      FileUtils.mkdir_p(cache_folder)
      Dir.chdir cache_folder do
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

      FileUtils.mkdir_p(cache_folder)
      begin
        text= href.read
      rescue OpenURI::HTTPError => http_error
        raise ValidationError, "Unable to fetch remote project: status=#{http_error.io.status[0]} url=#{href}"
      end
      File.open(File.join(cache_folder, File.basename(href.path)), "w") { |output|
        output.write text
      }
    end

    def fetch_with_http_recursive
      dir= File.dirname(cache_folder)
      FileUtils.mkdir_p(dir)
      fetcher= Distil::RecursiveHTTPFetcher.new(href, 1, dir)
      fetcher.fetch
    end
    
    def fetch
      self.send "fetch_with_#{@protocol}"
    end
    
    def update_with_git
      ensure_git
      Dir.chdir cache_folder do
        `git pull`
      end
    end
    
    def update_with_http
      fetch_with_http
    end
    
    def update
      self.send "update_with_#{@protocol}"
    end
    
    def build
      if !File.exist?(cache_folder)
        fetch
      else
        update
      end
      command= build_command
      return if command.empty?
      
      Dir.chdir(cache_folder) do
        exit 1 if !system("#{command}")
      end
    end
    
    def file_for(content_type, mode=nil)
      if :debug==mode || :import==mode
        file= File.join(include_path, "#{name}-debug.#{content_type}")
        return file if File.exists?(file)
      end
      file= File.join(include_path, "#{name}.#{content_type}")
      return file if File.exists?(file)
      
      candidates= Dir.glob(File.join(include_path, "*.#{content_type}"))
      return candidates.first if 1==candidates.length
      
      nil
    end

    def debug_file_for(content_type)
      file_for(content_type, :debug)
    end
    
  end
  
end
