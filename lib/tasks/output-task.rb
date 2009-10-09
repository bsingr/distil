require "#{$script_dir}/task.rb"
require 'zlib'

$compressor = "#{$vendor_dir}/yuicompressor-2.4.2.jar"

class OutputTask < Task
  attr_reader :concat, :debug
  
  declare_option :notice
  declare_option :output_folder

  def initialize(target_name, options)
    super(target_name, options)

    type= output_extension
    return if (!type)
    
    target_name= "#{target_name}".downcase
    prefix= "#{options.output_folder}/#{options.name}"
    
    if ("all"==target_name)
      target_name= ""
    else
      prefix= "#{prefix}-"
    end

    @name_concat= "#{prefix}#{target_name}-uncompressed.#{type}"
    @name_min= "#{prefix}#{target_name}.#{type}"
    @name_gz= "#{prefix}#{target_name}.#{type}.gz"
    @name_debug= "#{prefix}#{target_name}-debug.#{type}"

    @concat = ""
    @debug = ""
  end

  def output_type
    nil
  end
  
  def output_extension
    output_type
  end

  #  Do a simple token substitution. Tokens begin and end with @.
  def replace_tokens(string, params)
  	return string.gsub(/(\n[\t ]*)?@([^@ \t\r\n]*)@/) { |m|
  		key= $2
  		ws= $1
  		value= params[key]||m;
  		if (ws && ws.length)
  			ws + value.split("\n").join(ws);
  		else
  			value
  		end
  	}
  end

  def minify(working_file)
  	# Run the Y!UI Compressor
  	type= type || File.extname(working_file)[1..-1]
  	buffer = `java -jar #{$compressor} --type #{type} #{working_file}`
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
        @notice_text= "/*\n#{text}\n*/\n\n"
      end
    end
  
    return @notice_text
  end

  def process_all_files
    @included_files.each { |f|
      @concat << f.content
      @debug << f.debug_content
    }
  end

  def finish
    return if (!output_type)
    
    # Clear old files
    [@name_concat, @name_min, @name_gz, @name_debug].each { |file|
      next if (!File.exists?(file))
      File.delete(file)
    }

    return if (""==@concat)

    params= {
      "VERSION"=>@options.version
    }
    
    File.open(@name_concat, "w") { |f|
      f.write(notice_text)
      concat= replace_tokens(@concat, params)
      f.write(concat)
    }
    
    minified= minify(@name_concat)

    File.open(@name_min, "w") { |f|
      f.write(notice_text)
      f.write(minified)
    }
    
    Zlib::GzipWriter.open(@name_gz) { |f|
      f.write(notice_text)
      f.write(minified)
    }

    return if (""==@debug)
    
    File.open(@name_debug, "w") { |f|
      f.write(notice_text)
      debug= replace_tokens(@debug, params)
      f.write(debug)
    }
  end
  
end