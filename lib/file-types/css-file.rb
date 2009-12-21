class CssFile < SourceFile

  def self.extension
    ".css"
  end

  def minify_content_type
    "css"
  end
  
  def content
    return @content if (@content && @root_folder==@@root_folder)

    # Remember the value of the class root_folder variable, because it changes
    # where files are generated relative to.
    @root_folder= @@root_folder

    buffer= File.read(@full_path)
    # Replace all ' (single quotes) with " (double quotes) in
    # order to fix a problem with the background url regexp
    buffer.gsub!(/\'/,'"')
    # Force a newline after a rule terminating ; (semi-colon) 
    # in order to fix a problem with the background url regexp
    buffer.gsub!(/;(\n|\r)*/, ";\n")

    # Rewrites the 'url("...")' rules to a relative path 
    # based on the location of the new concatenated CSS file.
    line_num=0

    lines= buffer.split("\n")
    
    lines.each { |line|
    
      line_num+=1

      line.gsub!(/@import\s+url\("?(.*\.css)"?\)/) { |match|
        css_file= File.join(@parent_folder, $1)
        
        if (!File.exists?(css_file))
          error "imported CSS file not found: #{$1}", line_num
          # leave the @import rule in place
          match
        else
          dependency= SourceFile.from_path(css_file)
          @dependencies << dependency
        end
      }
      
      line.gsub!(/url\("?(.*\.(jpg|png|gif))"?\)/) { |match|
        image_file= File.join(@parent_folder, $1)

        if (!File.exists?(image_file))
          warning "resource not found: #{$1} (#{image_file})", line_num
          "url(\"#{$1}\")"
        else
          asset= SourceFile.from_path(image_file)
          @assets << asset
          # dependency.dependencies
          "url(\"{{FILEREF(#{asset})}}\")"
        end
      }
    }

    @content= lines.join("\n")
  end

  def debug_content_relative_to_destination(destination)
    "@import url(\"#{self.relative_to_folder(destination)}\");\n"
  end
  
end
