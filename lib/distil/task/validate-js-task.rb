module Distil

  LINT_COMMAND= "#{VENDOR_DIR}/jsl-0.3.0/bin/jsl"
  # LINT_COMMAND= "/Users/jeff/.gem/ruby/1.8/gems/distil-0.10.2/vendor/jsl-0.3.0/bin/jsl"
  
  class ValidateJsTask < Task

    include ErrorReporter
    
    option :jsl_conf, "#{LIB_DIR}/jsl.conf"
    
    def handles_file(file)
      return ["js"].include?(file.content_type)
    end

    def process_files(files)
      return if (!File.exists?(LINT_COMMAND))

      tmp= Tempfile.new("jsl.conf")
    
      conf_files= [ "jsl.conf",
                    "#{ENV['HOME']}/.jsl.conf",
                    jsl_conf
                  ]

      jsl_conf= conf_files.find { |f| File.exists?(f) }

      tmp << File.read(jsl_conf)
      tmp << "\n"

      tmp << "+define distil\n"
      
      # add aliases
      target.project.external_projects.each { |project|
        import_file= project.product_name(:import, 'js')
        next if !File.exist?(import_file)
        tmp << "+alias #{project.name} #{import_file}\n"
      }
    
      files.each { |f|
        next if !handles_file(f)
        tmp << "+process #{f}\n"
      }

      tmp.close()

      command= "#{LINT_COMMAND} -nologo -nofilelisting -conf #{tmp.path}"

      stdin, stdout, stderr= Open3.popen3(command)
      stdin.close
      output= stdout.read
      errors= stderr.read

      tmp.delete
    
      output= output.split("\n")
      summary= output.pop
      match= summary.match(/(\d+)\s+error\(s\), (\d+)\s+warning\(s\)/)
      if (match)
          @@error_count+= match[1].to_i
          @@warning_count+= match[2].to_i
      end
    
      output= output.join("\n")
    
      if (!output.empty?)
          puts output
          puts
      end

    end
    
  end
  
end