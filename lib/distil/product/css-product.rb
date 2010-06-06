module Distil

  class CssProduct < Product
    include Concatenated
    extension "css"
  end

  class CssMinifiedProduct < Product
    include Minified
    extension "css"
  end

  class CssDebugProduct < Product
    include Debug
    extension "css"

    def write_output
      return if up_to_date
      @up_to_date= true
      
      File.open(filename, "w") { |f|
        f.write(target.notice_text)
        
        external_files.each { |ext|
          next if !File.exist?(ext)
          f.write("@import url(\"#{relative_path(ext)});\n")
        }
      
        files.each { |file|
          f.write("@import url(\"#{relative_path(file)}\");\n")
        }
      }
    end
    
  end
  
end
