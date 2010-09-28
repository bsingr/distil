module Distil

  CSS_IMPORT_REGEX = /@import\s+url\("?(.*\.css)"?\)/
  CSS_IMAGE_URL_REGEX= /url\("?(.*\.(jpg|png|gif))"?\)/
  
  class CssFile < SourceFile

    extension "css"
    content_type "css"

    def dependencies
      @dependencies unless @dependencies.nil?

      text= content

      # Replace all ' (single quotes) with " (double quotes)
      text.gsub!(/\'/,'"')
      # Force a newline after a rule terminating ; (semi-colon)
      text.gsub!(/;(\n|\r)*/, ";\n")

      source_folder= project.source_folder
      
      # Rewrites the 'url("...")' rules to a relative path 
      # based on the location of the new concatenated CSS file.
      line_num=0

      text.each_line { |line|
    
        line_num+=1

        line.gsub(CSS_IMPORT_REGEX) { |match|
          css_file= File.join(dirname, $1)

          if (!File.exists?(css_file))
            error "Imported CSS file not found: #{$1}", line_num
            # leave the @import rule in place
            match
          else
            add_dependency(project.file_from_path(css_file))
          end
        }
      
        line.gsub(CSS_IMAGE_URL_REGEX) { |match|
          image_file= File.join(dirname, $1)

          if (!File.exists?(image_file))
            warning "Resource not found: #{$1} (#{image_file})", line_num
            "url(\"#{$1}\")"
          else
            asset= project.file_from_path(image_file)
            add_asset(asset)
            "url(\"#{asset.path_relative_to_folder(source_folder)}\")"
          end
        }
      }
    end
    
  end

end
