module Distil

  JSL_IMPORT_REGEX= /\/\*jsl:import\s+([^\*]*)\*\//
  
  class JslDependencyTask < Task

    def handles_file(file)
      return ["js"].include?(file.content_type)
    end

    def include_file(file)
      return if !handles_file(file)

      content= target.get_content_for_file(file).split("\n")
    
      line_num=0
    
      content.each { |line|
      
        line_num+=1
      
        # handle dependencies
        line.gsub!(JSL_IMPORT_REGEX) { |match|

          import_file= File.expand_path(File.join(file.parent_folder, $1))
          if (File.exists?(import_file))
            file.add_dependency SourceFile.from_path(import_file)
          else
            dependency= target.find_file($1, file)
            if (dependency)
              target.add_file_alias($1, dependency.full_path)
              file.add_dependency dependency
            else
              file.error "Missing import file: #{$1}", line_num
            end
          end
        
          # replace jsl import with empty string
          ""

        }
      
      }
    
      target.set_content_for_file(file, content.join("\n"))
    end
    
  end
  
end