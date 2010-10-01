module Distil

  class JavascriptProduct < Product
    content_type "js"
    variants [RELEASE_VARIANT, DEBUG_VARIANT]
    
    MODULE_TEMPLATE= ERB.new %q{
      distil.beginModule("<%=project.name%>", <%=json_for(definition)%>);
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
        if f.is_a?(RemoteAsset)
          required_files << project.relative_output_path_for(f.file_for(content_type, variant))
        else
          required_files << project.relative_output_path_for(f)
        end
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
      
      definition[:asset_paths]= asset_paths
      if RELEASE_VARIANT==variant
        definition[:asset_data]= asset_data
      else
        definition[:required]= required_files
      end
      
      MODULE_TEMPLATE.result binding
    end

    def build_release
      File.open(output_path, "w") { |output|
        output.puts module_definition
        
        files.each { |f|
          if f.is_a?(RemoteAsset)
            content= f.content_for(content_type, variant)
            output.puts "/* #{f.name} */"
          else
            content= f.rewrite_content_relative_to_path(nil)
            output.puts "/* #{f.relative_path} */"
          end

          next if !content || content.empty?
            
          output.puts content
          output.puts ""
        }
          
      }
    end

    def build_debug
      File.open(output_path, "w") { |output|
        
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
      
      FileUtils.mkdir_p(File.dirname(output_path))
      self.send "build_#{variant}"
    end
    
  end
  
end