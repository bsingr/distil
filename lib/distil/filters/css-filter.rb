require "distil/filters/file-reference-filter"

module Distil
  
  class CssDependencyFilter < FileReferenceFilter
  
    def handles_file(file)
      return ["css"].include?(file.content_type)
    end
  
    def preprocess_content(file, content)
      # Replace all ' (single quotes) with " (double quotes) in
      # order to fix a problem with the background url regexp
      content.gsub!(/\'/,'"')
      # Force a newline after a rule terminating ; (semi-colon) 
      # in order to fix a problem with the background url regexp
      content.gsub!(/;(\n|\r)*/, ";\n")

      # Rewrites the 'url("...")' rules to a relative path 
      # based on the location of the new concatenated CSS file.
      line_num=0

      lines= content.split("\n")
    
      lines.each { |line|
    
        line_num+=1

        line.gsub!(/@import\s+url\("?(.*\.css)"?\)/) { |match|
          css_file= File.join(file.parent_folder, $1)
        
          if (!File.exists?(css_file))
            file.error "imported CSS file not found: #{$1}", line_num
            # leave the @import rule in place
            match
          else
            file.add_dependency(SourceFile.from_path(css_file))
          end
        }
      
        line.gsub!(/url\("?(.*\.(jpg|png|gif))"?\)/) { |match|
          image_file= File.join(file.parent_folder, $1)

          if (!File.exists?(image_file))
            file.warning "resource not found: #{$1} (#{image_file})", line_num
            "url(\"#{$1}\")"
          else
            asset= SourceFile.from_path(image_file)
            file.add_asset(asset)
            "url(\"#{file_reference(asset)}\")"
          end
        }
      }
    
      lines.join("\n")
    end
  
  end

end
