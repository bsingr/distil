module Distil

  CSS_IMPORT_REGEX = /@import\s+url\("?(.*\.css)"?\)/
  
  class CssDependencyFilter < Task
  
    def handles_file(file)
      return ["css"].include?(file.content_type)
    end
  
    def include_file(file)
      return if !handles_file(file)

      content= target.get_content_for_file(file)

      # Replace all ' (single quotes) with " (double quotes)
      content.gsub!(/\'/,'"')
      # Force a newline after a rule terminating ; (semi-colon)
      content.gsub!(/;(\n|\r)*/, ";\n")

      source_folder= get_option("source_folder")
      
      # Rewrites the 'url("...")' rules to a relative path 
      # based on the location of the new concatenated CSS file.
      line_num=0

      lines= content.split("\n")
    
      lines.each { |line|
    
        line_num+=1

        line.gsub!(CSS_IMPORT_REGEX) { |match|
          css_file= File.join(file.parent_folder, $1)

          if (!File.exists?(css_file))
            file.error "Imported CSS file not found: #{$1}", line_num
            # leave the @import rule in place
            match
          else
            file.add_dependency(SourceFile.from_path(css_file))
          end
        }
      
        line.gsub!(/url\("?(.*\.(jpg|png|gif))"?\)/) { |match|
          image_file= File.join(file.parent_folder, $1)

          if (!File.exists?(image_file))
            file.warning "Resource not found: #{$1} (#{image_file})", line_num
            "url(\"#{$1}\")"
          else
            asset= SourceFile.from_path(image_file)
            file.add_asset(asset)
            "url(\"#{asset.relative_to_folder(source_folder)}\")"
          end
        }
      }
    
      target.set_content_for_file(file, lines.join("\n"))
    end
  
  end

end
