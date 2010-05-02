module Distil
  
  class FileSet
    include Enumerable
    include ErrorReporter
    attr_reader :files
  
    def initialize(value, owner=nil)
      @owner= owner
      @files= []
      self.files= value
    end

    def files=(set)
      case
      when (set.is_a?(String))
        include_file(set)
      when (set.is_a?(Array))
        set.each { |f| include_file(f) }
      end
    end

    def include?(file)
      @files.include?(file)
    end
    
    def self.from_options(set, owner)
      self.new(set, owner)
    end
  
    def include_file(file)
      if @owner
        full_path= File.expand_path(File.join([@owner.source_folder, file].compact))
      else
        full_path= File.expand_path(file)
      end
    
      if File.directory?(full_path)
        Dir.foreach(full_path) { |f|
            next if f[/^\./]
            include_file(File.join(file, f))
        }
        return
      end

      files= Dir.glob(full_path)
      if (files.length>0)
        files.each { |f|
          source_file= SourceFile.from_path(f)
          next if (@files.include?(source_file))
          @files << source_file
        }
        return
      end
    
      # file not found by globbing (would also find explicit reference)
      source_file= @owner.find_file(file) if @owner
      if !source_file
        puts "full_path=#{full_path}\nsource_folder=#{@owner.source_folder}"
        error("Unable to locate file: #{file}")
        return
      end
      return if (@files.include?(source_file))
      @files << source_file
    end
  
    def each
      @files.each { |f| yield f }
    end
  
  end

end