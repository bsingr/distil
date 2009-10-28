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
    else
      if (File.exists?(full_path))
        source_file= SourceFile.from_path(full_path)
      else
        source_file= Target.current.find_file(file)
        return if (!source_file)
      end
      
      return if (@files.include?(source_file))
      @files << source_file
    end
  end
  
  def each
    @files.each { |f| yield f }
  end
  
end
