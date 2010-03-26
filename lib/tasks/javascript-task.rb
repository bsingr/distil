require "open3"
require "tempfile.rb"
require "#{$script_dir}/tasks/single-output-task.rb"

$lint_command= "#{$vendor_dir}/jsl-0.3.0/bin/jsl"
$jsdoc_command= "#{$vendor_dir}/jsdoc-toolkit/jsrun.sh"

class JavascriptTask < SingleOutputTask

  option :bootstrap_file, "#{$script_dir}/bootstrap-template.js"
  option :jsl_conf, "#{$script_dir}/jsl.conf"
  option :jsdoc_conf, "#{$script_dir}/jsdoc.conf"
  option :jsdoc_template, "#{$vendor_dir}/jsdoc-extras/templates/coherent"
  option :jsdoc_plugins, "#{$vendor_dir}/jsdoc-extras/plugins"
  option :doc_folder, "doc"
  option :generate_docs, false
  option :generate_import, false
  option :class_list, ""
  option :class_list_template, "#{$vendor_dir}/jsdoc-extras/templates/classlist"

  output_type "js"
  
  task_name_alias "js"
  
  def initialize(target, options)
    super(target, options)
    @concatenation_join_string = "\n/*jsl:ignore*/;/*jsl:end*/\n"
    
    if (!class_list.empty?)
      @products << File.join(output_folder, class_list)
    end
    
    if (generate_docs)
      @products << File.join(doc_folder, "index.html")
    end
    
    type= output_extension
    return if (!type)

    if (!output_name.empty?)
      target_name= "#{output_name}"
      prefix= "#{output_folder}/"
    else
      target_name= "#{target.target_name}".downcase
      prefix= "#{output_folder}/#{project_name}"
      if ("all"==target_name)
        target_name= ""
      else
        prefix= "#{prefix}-"
      end
    end

    if (generate_import)
      @name_import= "#{prefix}#{target_name}-import#{type}"
      @products << @name_import
    end
  end
  
  # JsTask handles files that end in .js
  def handles_file?(file_name)
    "#{file_name}"[/\.js$/]
  end

  def validate_files

    return if (!File.exists?($lint_command))
        
    tmp= Tempfile.new("jsl.conf")
    
    conf_files= [ "jsl.conf",
                  "#{ENV['HOME']}/.jsl.conf",
                  @options.jsl_conf
                ]

    jsl_conf= conf_files.find { |f| File.exists?(f) }

    tmp << File.read(jsl_conf)
    tmp << "\n"
    
    external_projects.each { |project|
      tmp << "+include #{project["include"]}\n"
    }
    
    @included_files.each { |f|
      next if "js"!=f.content_type
      tmp << "+process #{f}\n"
    }

    tmp.close()
    
    command= "#{$lint_command} -nologo -nofilelisting -conf #{tmp.path}"
    
    stdin, stdout, stderr= Open3.popen3(command)
    stdin.close
    output= stdout.read
    errors= stderr.read

    tmp.delete
    
    output= output.split("\n")
    summary= output.pop
    match= summary.match(/(\d+)\s+error\(s\), (\d+)\s+warning\(s\)/)
    if (match)
        @target.error_count+= match[1].to_i
        @target.warning_count+= match[2].to_i
    end
    
    output= output.join("\n")
    
    if (!output.empty?)
        puts output
        puts
    end
      
  end

  def generate_class_list()
    tmp= Tempfile.new("jsdoc.conf")
    
    template= File.read(@options.jsdoc_conf)
    doc_files= @included_files.map { |f|
      p= f.file_path || f.relative_to_folder(options.remove_prefix||"")
      "\"#{p}\""
    }
    
    class_list_output= File.join(output_folder, class_list)
    
    conf= replace_tokens(template, {
                    "DOC_FILES"=>doc_files.join(",\n"),
                    "DOC_OUTPUT_DIR"=>output_folder,
                    "DOC_TEMPLATE_DIR"=>class_list_template,
                    "DOC_PLUGINS_DIR"=>jsdoc_plugins
                })

    tmp << conf
    tmp.close()
    
    command= "#{$jsdoc_command} -c=#{tmp.path}"
    
    stdin, stdout, stderr= Open3.popen3(command)
    stdin.close
    output= stdout.read
    errors= stderr.read

    tmp.delete
    
    puts errors
    puts output
  end
  
  def document_files()

    generate_class_list() if (!class_list.empty?)
    
    return if (!generate_docs)
    return if (!File.exists?($jsdoc_command))
    
    tmp= Tempfile.new("jsdoc.conf")
    
    template= File.read(@options.jsdoc_conf)
    doc_files= @included_files.map { |f|
      p= f.file_path || f.relative_to_folder(options.remove_prefix||"")
      "\"#{p}\""
    }
    
    conf= replace_tokens(template, {
                    "DOC_FILES"=>doc_files.join(",\n"),
                    "DOC_OUTPUT_DIR"=>doc_folder,
                    "DOC_TEMPLATE_DIR"=>jsdoc_template,
                    "DOC_PLUGINS_DIR"=>jsdoc_plugins
                })

    tmp << conf
    tmp.close()
    
    command= "#{$jsdoc_command} -c=#{tmp.path}"
    
    stdin, stdout, stderr= Open3.popen3(command)
    stdin.close
    output= stdout.read
    errors= stderr.read

    tmp.delete
    
    puts errors
    puts output
      
  end

  def process_files
    super
    template= File.read(@options.bootstrap_file)
    @debug= replace_tokens(template, {
              "LOAD_SCRIPTS" => @debug
            })
  end

  def finish
    super
    return if (!generate_import)

    File.delete(@name_import) if (File.exists?(@name_import))
    
    File.open(@name_import, "w") { |f|
      f.write(notice_text)
      
      @included_files.each { |inc|
        f.puts "/*jsl:import #{inc.relative_to_folder(output_folder)}*/"
      }
    }
  end
  
end
