module Distil

  JSL_CONF= "#{LIB_DIR}/jsl.conf"
  # LINT_COMMAND= "#{VENDOR_DIR}/jsl-0.3.0/bin/jsl"
  LINT_COMMAND= "/Users/jeff/.gem/ruby/1.8/gems/distil-0.13.1/vendor/jsl-0.3.0/bin/jsl"
  JS_GLOBALS= Set.new ['Array', 'Boolean', 'Date', 'Error', 'EvalError',
                       'Function', 'Math', 'Number', 'Object', 'RangeError',
                       'ReferenceError', 'RegExp', 'String', 'SyntaxError',
                       'TypeError', 'URIError']
  
  module JavascriptFileValidator

    include ErrorReporter
    
    def validate_javascript_files
      return if (!File.exists?(LINT_COMMAND))

      tmp= Tempfile.new("jsl.conf")
    
      conf_files= [ "jsl.conf",
                    "#{ENV['HOME']}/.jsl.conf",
                    JSL_CONF
                  ]

      jsl_conf= conf_files.find { |f| File.exists?(f) }

      tmp << File.read(jsl_conf)
      tmp << "\n"

      tmp << "+define distil\n"
      
      if (global_export)
        tmp << "+define #{global_export}\n"
      end
      
      additional_globals.each { |g|
        next if JS_GLOBALS.include?(g)
        tmp << "+define #{g}\n"
      }
      
      source_files.each { |f|
        if f.is_a?(RemoteAsset)
          tmp.puts "+alias #{f.name} #{f.file_for(:js, DEBUG_VARIANT)}"
        else
          tmp.puts "+process #{f}" if f.content_type=="js"
        end
      }

      tmp.close()
      command= "#{LINT_COMMAND} -nologo -nofilelisting -conf #{tmp.path}"

      # puts "jsl conf:\n#{File.read(tmp.path)}\n\n"
      
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
