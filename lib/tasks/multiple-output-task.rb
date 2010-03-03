require "#{$script_dir}/tasks/output-task.rb"

class MultipleOutputTask < OutputTask

  def initialize(target, options)
    super(target, options)

    type= output_extension
    return if (!type)
    
    target_name= "#{target.target_name}".downcase
    if ('all'!=target_name)
      @options.output_folder= File.join(output_folder, target_name)
    end
    
    prefix= "#{output_folder}/"
    
    # if ("all"!=target_name)
    #   prefix= "#{prefix}#{target_name}/"
    # end
    
    # @options.output_folder= prefix
    FileUtils.mkdir_p(output_folder)

    @concatenation_join_string= ""
    
    @prefix= prefix
    @concat= Hash.new
    @debug= Hash.new
  end

  def products
    @products if @products
    
    @products= []
    
    type= output_extension
    @included_files.each { |file|
      basename= file.basename("#{type}")
      name_concat= "#{@prefix}#{basename}-uncompressed#{type}"
      name_min= "#{@prefix}#{basename}#{type}"
      name_gz= "#{@prefix}#{basename}#{type}.gz"
      name_debug= "#{@prefix}#{basename}-debug#{type}"
      @products.concat([name_concat, name_min, name_gz, name_debug])
    }
    @products
  end
  
  def process_file(file)
    concat= ""
    debug= ""

    file.dependencies.each { |depend|
      next if !@files_to_include.include?(depend)
      next if @files_to_exclude.include?(depend)
      
      concat << depend.filtered_content(options)
      if (!concat.empty?)
        concat << @concatenation_join_string||""
      end
      debug << depend.debug_content(options)
    }
    
    if (!concat.empty?)
      concat << @concatenation_join_string||""
    end
    concat << file.filtered_content(options)
    debug << file.debug_content(options)
    
    @concat[file]= concat
    @debug[file]= debug
  end
  
  def process_files
    @included_files.each { |f|
      process_file(f)
    }
  end

  def finish_file(file)
    type= output_extension
    return if (!type)

    basename= file.basename("#{type}")
    name_concat= "#{@prefix}#{basename}-uncompressed#{type}"
    name_min= "#{@prefix}#{basename}#{type}"
    name_gz= "#{@prefix}#{basename}#{type}.gz"
    name_debug= "#{@prefix}#{basename}-debug#{type}"
    
    # puts "Finish: #{file}"
    # puts "  #{name_concat}"
    # puts "  #{name_min}"
    # puts "  #{name_gz}"
    # puts "  #{name_debug}"
    # 
    # Clear old files
    [name_concat, name_min, name_gz, name_debug].each { |f|
      next if (!File.exists?(f))
      File.delete(f)
    }

    params= {
      "VERSION"=>version
    }
    
    concat= replace_tokens(@concat[file], params)
    return if (""==concat)
    
    File.open(name_concat, "w") { |f|
      f.write(notice_text)
      f.write(concat)
    }
    
    minified= minify(concat)

    File.open(name_min, "w") { |f|
      f.write(notice_text)
      f.write(minified)
    }
    
    Zlib::GzipWriter.open(name_gz) { |f|
      f.write(notice_text)
      f.write(minified)
    }

    debug= replace_tokens(@debug[file], params)
    return if (""==debug)
    
    File.open(name_debug, "w") { |f|
      f.write(notice_text)
      f.write(debug)
    }
  end

  def finish
    @included_files.each { |f|
      finish_file(f)
    }
  end
end
