module Distil
  
  class CssProduct < Product
    content_type "css"
    variants [RELEASE_VARIANT, DEBUG_VARIANT]

    def build_debug
      File.open(output_path, "w") { |output|

        output.puts notice_comment
        output_files= []
        
        libraries.each { |l|
          f= project.file_from_path(l.file_for(content_type, language, variant))
          output_files << f if f
        }

        output_files += files
        
        output_files.each { |f|
          output.puts "@import url(\"#{f.relative_path}\");"
        }
        
      }
    end

    def build_release
      File.open(output_path, "w") { |output|

        output.puts notice_comment

        output_files= []
        
        libraries.each { |l|
          f= project.file_from_path(l.file_for(content_type, language, variant))
          output_files << f if f
        }

        output_files += files
        
        output_files.each { |f|
          content= f.rewrite_content_relative_to_path(nil)
          next if !content || content.empty?

          output.puts "/* #{f.relative_path} */"
          output.puts content
          output.puts ""
        }
        
      }
    end
    
  end
  
end
