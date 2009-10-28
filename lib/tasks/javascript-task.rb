require "open3"
require "tempfile.rb"
require "#{$script_dir}/tasks/output-task.rb"

$lint_command= "#{$vendor_dir}/jsl-0.3.0/bin/jsl"
$jsdoc_command= "#{$vendor_dir}/jsdoc-toolkit/jsrun.sh"

class JavascriptTask < OutputTask

  declare_option :bootstrap_file, "#{$script_dir}/bootstrap-template.js"
  declare_option :jsl_conf, "#{$script_dir}/jsl.conf"
  declare_option :jsdoc_conf, "#{$script_dir}/jsdoc.conf"
  declare_option :jsdoc_template, "#{$vendor_dir}/jsdoc-toolkit/templates/coherent"
  declare_option :doc_folder, "doc"
  declare_option :generate_docs, false
  
  def self.task_name
    "js"
  end
  
  def output_type
    "js"
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
    
    @options.external_projects.each { |project|
      tmp << "+include #{project["include"]}\n"
    }
    
    @included_files.each { |f|
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

  def document_files()
      
    return if (!@options.generate_docs)
    return if (!File.exists?($jsdoc_command))
    
    tmp= Tempfile.new("jsdoc.conf")
    
    template= File.read(@options.jsdoc_conf)
    doc_files= @included_files.map { |f| "\"#{f.file_path}\"" }
    
    conf= replace_tokens(template, {
                    "DOC_FILES"=>doc_files.join(",\n"),
                    "DOC_OUTPUT_DIR"=>@options.doc_folder,
                    "DOC_TEMPLATE_DIR"=>@options.jsdoc_template
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
  
end
