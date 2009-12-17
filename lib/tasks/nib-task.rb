require "#{$script_dir}/tasks/output-task.rb"
require "#{$script_dir}/tasks/javascript-task.rb"

class NibTask < MultipleOutputTask

  def self.task_name
    "jsnib"
  end

  def source_type
    "js"
  end
  
  def output_type
    "jsnib"
  end
  
  # NibTask handles files that end in .jsnib
  def handles_file?(file_name)
    "#{file_name}"[/\.jsnib$/]
  end

  def validate_file(file)

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
    
    file.dependencies.each { |f|
      tmp << "+process #{f}\n"
    }
    
    tmp << "+process #{file}\n"
    
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

  def validate_files
    @included_files.each { |f|
      validate_file(f)
    }
  end
  
end
