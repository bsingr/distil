module Distil
  
  # Mix in for concatenating products
  module Concatenated
    
    # files -> an enumerable collection of SourceFiles
    # join_string -> a string to use to join the files together
    # target -> the container of the files
    
    def concatenated_prefix
      ""
    end

    def concatenated_suffix
      ""
    end
    
    def filename
      concatenated_name
    end
    
    def write_output
      return if up_to_date
      @up_to_date= true
      
      File.open(filename, "w") { |f|
        f.write(target.notice_text)
        f.write("\n\n")

        target.project.external_projects.each { |ext|
          next if STRONG_LINKAGE!=ext.linkage
          
          concatenated_file= ext.product_name(:concatenated, File.extname(filename)[1..-1])
          next if !File.exist?(concatenated_file)
          f.write(join_string)
          f.write(target.get_content_for_file(concatenated_file))
        }

        f.write("\n\n")
        f.write(concatenated_prefix)
        f.write("\n\n")

        files.each { |file|
          f.write(join_string)
          f.write(target.get_content_for_file(file))
        }
        
        f.write("\n\n")
        f.write(concatenated_suffix)
        f.write("\n\n");
        
        assets.each { |file|
          f.write(embed_file(file))
        }
        
      }
    end

  end
  
end