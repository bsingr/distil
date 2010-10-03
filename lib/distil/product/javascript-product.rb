module Distil

  BOOTSTRAP_SCRIPT= "#{ASSETS_DIR}/distil.js"
  FILE_SEPARATOR= "        /*jsl:ignore*/;/*jsl:end*/"
  
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

  end
  
end