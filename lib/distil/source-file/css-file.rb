module Distil

  CSS_IMPORT_REGEX = /@import\s+url\("?(.*\.css)"?\)/
  CSS_IMAGE_URL_REGEX= /url\("?(.*\.(jpg|png|gif))"?\)/
  
  class CssFile < SourceFile

    extension "css"
    content_type "css"

    def content
      return @content unless @content.nil?
      @content= File.read(full_path)
      # Replace all ' (single quotes) with " (double quotes)
      @content.gsub!(/\'/,'"')
      # Force a newline after a rule terminating ; (semi-colon)
      @content.gsub!(/;(\n|\r)*/, ";\n")
      @content
    end

    def rewrite_content_relative_to_path(path)
      content.gsub(CSS_IMAGE_URL_REGEX) { |match|
        image_file= File.join(dirname, $1)

        if (!File.exists?(image_file))
          match
        else
          asset= project.file_from_path(image_file)
          "url(\"#{asset.relative_path}\")"
        end
      }
    end

    def dependencies
      @dependencies unless @dependencies.nil?

      line_num=0
      content.each_line { |line|
        line_num+=1

        line.scan(CSS_IMPORT_REGEX) { |match|
          css_file= File.join(dirname, $1)

          if (!File.exists?(css_file))
            error "Imported CSS file not found: #{$1}", line_num
          else
            add_dependency(project.file_from_path(css_file))
          end
        }
      
        line.scan(CSS_IMAGE_URL_REGEX) { |match|
          image_file= File.join(dirname, $1)

          if (!File.exists?(image_file))
            warning "Resource not found: #{$1} (#{image_file})", line_num
          else
            asset= project.file_from_path(image_file)
            add_asset(asset)
          end
        }
      }
    end
    
  end

end
