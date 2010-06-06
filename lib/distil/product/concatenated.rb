module Distil
  
  # Mix in for concatenating products
  module Concatenated
    
    # files -> an enumerable collection of SourceFiles
    # join_string -> a string to use to join the files together
    # target -> the container of the files
    
    def before_files(f)
    end

    def after_files(f)
    end
    
    def before_externals(f)
    end
    
    def after_externals(f)
    end
    
    def before_file(f, file)
    end
    
    def after_file(f, file)
    end
    
    def filename
      concatenated_name
    end
    
    def external_files
      return @external_files if @external_files
      @external_files= []
      
      target.project.external_projects.each { |ext|
        next if STRONG_LINKAGE!=ext.linkage
        
        @external_files << ext.product_name(:concatenated, File.extname(filename)[1..-1])
      }
      @external_files
    end
    
    def write_output
      return if up_to_date
      @up_to_date= true
      
      File.open(filename, "w") { |f|
        f.write(target.notice_text)

        f.write("\n\n")
        before_externals(f)
        f.write("\n\n")
        
        external_files.each { |ext|
          next if !File.exist?(ext)
          f.write(join_string)
          f.write(target.get_content_for_file(ext))
        }

        f.write("\n\n")
        after_externals(f)
        f.write("\n\n")

        f.write("\n\n")
        before_files(f)
        f.write("\n\n")

        files.each { |file|
          f.write(join_string)
          before_file(f, file)
          f.write(target.get_content_for_file(file))
          after_file(f, file)
        }
        
        f.write("\n\n")
        after_files(f)
        f.write("\n\n");
        
      }
    end

  end
  
end