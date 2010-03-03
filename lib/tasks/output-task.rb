require "#{$script_dir}/task.rb"
require 'zlib'

$compressor = "#{$vendor_dir}/yuicompressor-2.4.2.jar"

class OutputTask < Task
  option :notice
  option :output_folder, "build"
  option :include, FileSet
  option :exclude, FileSet
  
  def initialize(target, options)
    super(target, options)
    @files_to_exclude= @options.exclude.to_a
    @files_to_include= @options.include.to_a
    FileUtils.mkdir_p(output_folder)
  end

  class_attr :output_type
  class_attr :content_type
  
  def self.content_type(*rest)
    if (rest.length>0)
      @content_type= rest[0]
    else
      @content_type || output_type
    end
  end
  
  def output_extension
    output_type && ".#{output_type}"
  end

  def products
    @products
  end
  
  def minify(source)
  	# Run the Y!UI Compressor
  	buffer= ""
  	
  	IO.popen("java -jar #{$compressor} --type #{content_type}", "r+") { |pipe|
  	  pipe.puts(source)
  	  pipe.close_write
  	  buffer= pipe.read
	  }
	  
    # buffer = `java -jar #{$compressor} --type #{type} #{working_file}`
  	if ('css'==output_type)
  		# puts each rule on its own line, and deletes @import statements
  		return buffer.gsub(/\}/,"}\n").gsub(/.*@import url\(\".*\"\);/,'')
  	else
  		return buffer
  	end
  end
  
  def notice_text
    if (!@options.notice)
      return ""
    end
    
    if (nil==@notice_text)
      notice_file= @options.notice;
      if (!File.exists?(notice_file))
        @notice_text= ""
      else
        text= File.read(notice_file).strip
        text= "    #{text}".gsub(/\n/, "\n    ")
        @notice_text= "/*!\n#{text}\n*/\n\n"
      end
    end
  
    return @notice_text
  end
  
end