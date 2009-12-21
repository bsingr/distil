$jsl_import_regex= /\/\*jsl:import\s+([^\*]*)\*\//
$include_regex= /NIB\.asset\(['"]([^)]+)['"]\)/

class JavascriptFile < SourceFile

  def self.extension
    ".js"
  end

  def can_embed_as_content
    true
  end

  def minify_content_type
    "js"
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
          error "Missing import file: #{$1}", line_num
          "NIB.asset('#{$1}')"
        else
          asset= SourceFile.from_path(import_file)
          @assets << asset
          if (asset.can_embed_as_content)
            "NIB.asset('{{FILEREF(#{asset})}}','{{CONTENTREF(#{asset})}}')"
          else
            "NIB.asset('{{FILEREF(#{asset})}}')"
            # include_content= asset.content.gsub("\\", "\\\\").gsub(/>\s+</, "><").gsub("\n", "\\n").gsub("\"", "\\\"").gsub("'", "\\\\'")
            # "INC('{{FILEREF(#{asset})}}','{{CONTENTREF(#{asset})}}')"
          end
        end
        
      }
      
    }

    # return the array of dependencies
    @content= content.join("\n") + "\n"
  end

  def content_relative_to_destination(destination)
    relative= super(destination)
    relative.gsub(/\{\{CONTENTREF\(([^)]*)\)\}\}/) { |match|
      file= SourceFile.from_path($1)
      included_content= file.content_relative_to_destination(destination)
      included_content= file.minify_content(included_content)
      included_content.gsub("\\", "\\\\").gsub(/>\s+</, "><").gsub("\n", "\\n").gsub("\"", "\\\"").gsub("'", "\\\\'")
    }
  end
  
  def debug_content_relative_to_destination(destination)
    path= @file_path ? @file_path : self.relative_to_folder(destination)
    "loadScript(\"#{path}\");\n"
  end

end
