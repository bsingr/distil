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
    extension "css"

    def filename
      debug_name
    end
    
    def write_output
      return if up_to_date
      @up_to_date= true
      
      File.open(filename, "w") { |f|
        f.write(target.notice_text)
        
        target.project.external_projects.each { |ext|
          next if STRONG_LINKAGE!=ext.linkage
        
          debug_file= ext.product_name(:debug, "css")
          next if !File.exist?(debug_file)
          f.write("@import url(\"#{relative_path(debug_file)});\n")
        }
      
        files.each { |file|
          f.write("@import url(\"#{relative_path(file)}\");\n")
        }
      }
    end
    
  end
  
end
