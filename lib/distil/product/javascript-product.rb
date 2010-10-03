module Distil

  JSL_CONF= "#{LIB_DIR}/jsl.conf"
  # LINT_COMMAND= "#{VENDOR_DIR}/jsl-0.3.0/bin/jsl"
  LINT_COMMAND= "/Users/jeff/.gem/ruby/1.8/gems/distil-0.13.1/vendor/jsl-0.3.0/bin/jsl"
  BOOTSTRAP_SCRIPT= "#{ASSETS_DIR}/distil.js"
  FILE_SEPARATOR= "        /*jsl:ignore*/;/*jsl:end*/"
  
  JS_GLOBALS= Set.new ['Array', 'Boolean', 'Date', 'Error', 'EvalError',
                       'Function', 'Math', 'Number', 'Object', 'RangeError',
                       'ReferenceError', 'RegExp', 'String', 'SyntaxError',
                       'TypeError', 'URIError']

  class JavascriptProduct < Product
    content_type "js"
    variants [RELEASE_VARIANT, DEBUG_VARIANT]
    
    include ErrorReporter
    
    MODULE_TEMPLATE= ERB.new %q{
      distil.module("<%=project.name%>", <%=json_for(definition)%>);
    }.gsub(/^      /, '')
    
    def can_embed_as_content(file)
      ["css", "html", "json"].include?(file.extension)
    end

    def escape_embeded_content(file)
      content= file.rewrite_content_relative_to_path(nil)
      file.minified_content(content)
      # return content if content_type==file.content_type
      # content.gsub("\\", "\\\\").gsub("\n", "\\n").gsub("\"", "\\\"").gsub("'", "\\\\'")
    end

    def json_for(obj)
      JSON.generate(obj)
    end
    
    def module_definition
      asset_paths= {}
      asset_data= {}
      definition= {}
      required_files= []
      
      files.each { |f|
        f= f.file_for(content_type, variant) if f.is_a?(RemoteAsset)
        next if !f
        
        required_files << project.relative_output_path_for(f)
      }
      
      assets.each { |asset|
        next if project.source_files.include?(asset)

        if RELEASE_VARIANT==variant
          key= project.asset_aliases[asset]||asset.relative_path
          if can_embed_as_content(asset)
            asset_data[key]= escape_embeded_content(asset)
          end
        else
          key= project.asset_aliases[asset]
          asset_paths[key]= project.relative_output_path_for(asset) if key
        end
      }
      
      definition[:asset_map]= asset_paths
      if RELEASE_VARIANT==variant
        definition[:assets]= asset_data
      else
        definition[:required]= required_files
      end
      
      MODULE_TEMPLATE.result binding
    end

    def build_release
      File.open(output_path, "w") { |output|
        
        output.write(project.notice_text)

        if (APPLICATION_TYPE==project.project_type)
          output.puts File.read(BOOTSTRAP_SCRIPT)
          output.puts FILE_SEPARATOR
        end

        # emit remote assets first
        files.each { |f|
          next unless f.is_a?(RemoteAsset)
          content= f.content_for(content_type, variant)
          next unless content && !content.empty?
          output.puts content
          output.puts FILE_SEPARATOR
        }
        
        output.puts module_definition

        if project.global_export
          exports= [project.global_export, *project.additional_globals].join(", ")
          output.puts "(function(#{exports}){"
        end

        files.each { |f|
          next if f.is_a?(RemoteAsset)
          content= f.rewrite_content_relative_to_path(nil)

          next if !content || content.empty?
            
          output.puts content
          output.puts ""
          output.puts FILE_SEPARATOR
        }
        
        if project.global_export
          exports= ["window.#{project.global_export}=window.#{project.global_export}||{}", *project.additional_globals].join(", ")
          output.puts "})(#{exports});"
        end
        
        output.puts "distil.moduleDidLoad('#{project.name}');"  
      }
    end

    def build_debug
      File.open(output_path, "w") { |output|
        
        output.write(project.notice_text)
        
        if (APPLICATION_TYPE==project.project_type)
          output.puts File.read(BOOTSTRAP_SCRIPT)
        end
        
        if project.global_export
          output.puts
          output.puts "window.#{project.global_export}=window.#{project.global_export}||{};"
          output.puts
        end
        
        files.each { |f|
          if f.is_a?(RemoteAsset)
            path= project.relative_output_path_for(f.file_for(content_type, variant))
          else
            path= project.relative_output_path_for(f)
          end
          
          next if !path
          output.puts "/*jsl:import #{path}*/"
        }


        output.puts module_definition
          
      }
    end

    def build
      return if up_to_date?
      
      puts "\n#{filename}:\n\n"
      validate_files
      
      FileUtils.mkdir_p(File.dirname(output_path))
      self.send "build_#{variant}"
      report
    end
    
    def validate_files
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
      
      if (project.global_export)
        tmp << "+define #{project.global_export}\n"
      end
      
      project.additional_globals.each { |g|
        next if JS_GLOBALS.include?(g)
        tmp << "+define #{g}\n"
      }
      
      files.each { |f|
        if f.is_a?(RemoteAsset)
          tmp.puts "+alias #{f.name} #{f.file_for(content_type, DEBUG_VARIANT)}"
        else
          tmp.puts "+process #{f}"
        end
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