require "#{$script_dir}/source-file"

class FileSet
  include Enumerable
  attr_reader :files
  
  def initialize(set)
   @files= []
   case
     when (set.is_a?(String))
       include_file(set)
     when (set.is_a?(Array))
       set.each { |f| include_file(f) }
    end
  end
  
  def include_file(file)
    full_path= File.expand_path(file)

    if File.directory?(full_path)
      Dir.foreach(full_path) { |f|
          next if ('.'==f[/^\./])
          include_file(File.join(full_path, f))
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
    source_file= Project.current.find_file(file)
    return if (!source_file)
    return if (@files.include?(source_file))
    @files << source_file
  end
  
  def each
    @files.each { |f| yield f }
  end
  
end
