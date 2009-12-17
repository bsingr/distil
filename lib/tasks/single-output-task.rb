require "#{$script_dir}/tasks/output-task.rb"

class SingleOutputTask < OutputTask

  def initialize(target, options)
    super(target, options)

    type= output_extension
    return if (!type)
    
    target_name= "#{target.target_name}".downcase
    prefix= "#{output_folder}/#{project_name}"
    
    if ("all"==target_name)
      target_name= ""
    else
      prefix= "#{prefix}-"
    end

    @name_concat= "#{prefix}#{target_name}-uncompressed.#{type}"
    @name_min= "#{prefix}#{target_name}.#{type}"
    @name_gz= "#{prefix}#{target_name}.#{type}.gz"
    @name_debug= "#{prefix}#{target_name}-debug.#{type}"

    @products= [@name_concat, @name_min, @name_gz, @name_debug]
    
    @concat = ""
    @debug = ""
  end

  def process_files
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
    
    concat= replace_tokens(@concat, params)

    File.open(@name_concat, "w") { |f|
      f.write(notice_text)
      f.write(concat)
    }
    
    minified= minify(concat)

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

