module Distil
  
  class CssProduct < Product
    content_type "css"
    variants [RELEASE_VARIANT, DEBUG_VARIANT]

    def build_debug
      File.open(output_path, "w") { |output|

        output.puts notice_comment

        files.each { |f|
          if f.is_a?(RemoteAsset)
            path= f.file_for(content_type, variant)
          else
            path= f.relative_path
          end
          
          next if !path
          output.puts "@import url(#{path});"
        }
        
      }
    end

    def build_release
      File.open(output_path, "w") { |output|

        output.puts notice_comment
        
        files.each { |f|
          if f.is_a?(RemoteAsset)
            content= f.content_for(content_type, variant)
            output.puts "/* #{f.name} */"
          else
            content= f.rewrite_content_relative_to_path(nil)
            output.puts "/* #{f.relative_path} */"
          end

          next if !content || content.empty?
            
          output.puts content
          output.puts ""
        }
        
      }
    end
    
  end
  
end
