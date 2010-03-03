$jsl_import_regex= /\/\*jsl:import\s+([^\*]*)\*\//

class JslDependencyFilter < Filter
  
  def handles_file(file)
    return ["js"].include?(file.content_type)
  end
  
  def preprocess_content(file, content)

    content= content.split("\n")
    
    line_num=0
    
    content.each { |line|
      
      line_num+=1
      
      # handle dependencies
      line.gsub!($jsl_import_regex) { |match|

        import_file= File.expand_path(File.join(file.parent_folder, $1))
        if (File.exists?(import_file))
          file.add_dependency SourceFile.from_path(import_file)
        else
          dependency= Project.current.find_file($1)
          if (dependency)
            file.add_dependency SourceFile.from_path(import_file)
          else
            file.error "Missing import file: #{$1}", line_num
          end
        end
        
        # replace jsl import with empty string
        ""

      }
      
    }
    
    content.join("\n")
  end
  
end
