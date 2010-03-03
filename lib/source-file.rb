require 'fileutils'

$compressor = "#{$script_dir}/yuicompressor-2.4.2.jar"

class SourceFile
  attr_accessor :parent_folder, :full_path

  def initialize(filepath)
    @full_path= File.expand_path(filepath)

    @parent_folder= File.dirname(@full_path)
    @dependencies= []
    @assets= []
    
    @@file_cache[@full_path]= self
  end

  def self.extension
  end
  
  def extension
    self.class.extension
  end
  
  def can_embed_as_content(file)
    false
  end
  
  def content_type
    ext= self.extension
    return if !ext
    ext[1..-1]
  end
  
  @@file_types= []
  def self.inherited(subclass)
    @@file_types << subclass
  end

  def self.file_types
    @@file_types
  end

  @@file_cache= Hash.new
  def self.from_path(filepath)
    full_path= File.expand_path(filepath)
    file= @@file_cache[full_path]
    return file if file
    
    extension= File.extname(filepath)
    
    @@file_types.each { |handler|
      next if (handler.extension != extension)

      return handler.new(filepath)
    }
    
    return SourceFile.new(filepath)
  end

  def to_s
    @full_path
  end
  
  def to_str
    @full_path
  end

  def error(message, line_number=0)
    Target.current.error(message, self, line_number)
  end

  def warning(message, line_number=0)
    Target.current.warning(message, self, line_number)
  end

  def basename(suffix="")
    File.basename(@full_path, suffix)
  end
  
  def file_path
    @file_path
  end

  def file_path=(path)
    @file_path=path
  end
  
  def load_content
    content= File.read(@full_path)
    Filter.each { |f|
      next if !f.handles_file(self)
      content= f.preprocess_content(self, content)
    }
    content
  end

  def escape_embeded_content(content)
    content
  end
  
  def content
    @content ||= load_content
  end

  def filtered_content(options)
    c= content || ""
    Filter.each { |f|
      next if !f.handles_file(self)
      c= f.filter_content(self, c, options)
    }
    c
  end
    
  def debug_content(options)
    self.filtered_content(options)
  end
  
  def minify_content(source)
  	# Run the Y!UI Compressor
    return source if !content_type
  	buffer= ""
    
  	IO.popen("java -jar #{$compressor} --type #{content_type}", "r+") { |pipe|
  	  pipe.puts(source)
  	  pipe.close_write
  	  buffer= pipe.read
	  }
	  
    # buffer = `java -jar #{$compressor} --type #{type} #{working_file}`
  	if ('css'==content_type)
  		# puts each rule on its own line, and deletes @import statements
  		return buffer.gsub(/\}/,"}\n").gsub(/.*@import url\(\".*\"\);/,'')
  	else
  		return buffer
  	end
  end
  
  def self.path_relative_to_folder(path, folder)
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
  
  def relative_to_folder(output_folder)
    self.class.path_relative_to_folder(@full_path, output_folder)
  end

  def relative_to_file(source_file)
    folder= File.dirname(File.expand_path(source_file))
    self.relative_to_folder(folder)
  end
  
  def dependencies
    content
    @dependencies
  end

  def add_dependency(file)
    return if @dependencies.include?(file)
    @dependencies << file
  end
  
  def assets
    content
    @assets
  end
  
  def add_asset(file)
    @assets << file
  end
  
  def copy_to(folder, prefix)
    file_path= self.file_path || relative_to_folder(prefix||"")
    final_target_folder= File.join(folder, File.dirname(file_path))
    FileUtils.mkdir_p final_target_folder
    FileUtils.cp self.full_path, final_target_folder
    File.join(final_target_folder, File.basename(file_path))
  end
  
end

# load all the other file types
Dir.glob("#{$script_dir}/file-types/*-file.rb") { |file|
  require file
}
