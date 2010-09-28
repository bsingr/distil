module Distil

  class JavascriptProduct < Product
    content_type "js"

    MODULE_TEMPLATE= ERB.new %q{
      distil.beginModule("<%=project.name%>", <%=json_for(definition)%>);
    }.gsub(/^      /, '')
    
    def can_embed_as_content(file)
      ["css", "html", "json"].include?(file.extension)
    end

    def escape_embeded_content(file)
      content= file.minified_content
      # return content if content_type==file.content_type
      # content.gsub("\\", "\\\\").gsub("\n", "\\n").gsub("\"", "\\\"").gsub("'", "\\\\'")
    end

    def json_for(obj)
      JSON.generate(obj)
    end
    
    def module_definition(mode)
      source_folder= project.source_folder
      asset_paths= {}
      asset_data= {}
      definition= {}
      
      files.each { |f|
        f.assets.each { |a|
          next if project.product_files.include?(a)
          relative= a.path_relative_to_folder(f.dirname)

          if :release==mode && can_embed_as_content(a)
            asset_data[relative]= escape_embeded_content(a)
          else
            asset_paths[relative]= a.path_relative_to_folder(source_folder)
          end
        }
      }
      
      project.asset_aliases.each { |name, asset|
        if :release==mode && can_embed_as_content(asset)
          asset_data[name]= escape_embeded_content(asset)
        else
          asset_paths[name]= asset.path_relative_to_folder(source_folder)
        end
      }
      
      definition[:asset_paths]= asset_paths
      definition[:asset_data]= asset_data if :release==mode
      
      MODULE_TEMPLATE.result binding
    end
    
  end
  
end