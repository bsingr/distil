$jsl_import_regex= /\/\*jsl:import\s+([^\*]*)\*\//
$include_regex= /INC\(['"]([^)]+)['"]\)/

class JavascriptFile < SourceFile

  def self.extension
    ".js"
  end

  def content
    return @content if (@content && @root_folder==@@root_folder)

    # Remember the value of the class root_folder variable, because it changes
    # where files are generated relative to.
    @root_folder= @@root_folder

    @dependencies= []
    content= File.read(@full_path).split("\n")
    
    line_num=0
    
    content.each { |line|
      
      line_num+=1
      
      # handle dependencies
      line.gsub!($jsl_import_regex) { |match|

        import_file= File.expand_path(File.join(@parent_folder, $1))
        
        if (File.exists?(import_file))
          dependency= SourceFile.from_path(import_file)
          @dependencies << dependency
        else
          dependency= Target.current.find_file($1)
          if (dependency)
            @dependencies << dependency
          else
            error "Missing import file: #{$1}", line_num
          end
        end
        
        # replace jsl import with empty string
        ""

      }
      
      line.gsub!($include_regex) { |match|

        import_file= File.expand_path(File.join(@parent_folder, $1))

        if (!File.exists?(import_file))
          error "Missing import file: #{$1}", file_name, line_num
          "INC('#{$1}')"
        else
          asset= SourceFile.from_path(import_file)
          @assets << asset
          include_content= asset.content.gsub("\\", "\\\\").gsub(/>\s+</, "><").gsub("\n", "\\n").gsub("\"", "\\\"").gsub("'", "\\\\'")
          "INC('#{asset.file_path}','#{include_content}')"
        end
        
      }
      
    }

    # return the array of dependencies
    @content= content.join("\n") + "\n"
  end

  def debug_content
    "loadScript(\"#{self.file_path}\");\n"
  end

end
