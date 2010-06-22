module Distil
  
  # Mix in for concatenating products
  module Debug
    
    # files -> an enumerable collection of SourceFiles
    # join_string -> a string to use to join the files together
    # target -> the container of the files
    
    def before_files(f)
    end

    def after_files(f)
    end
    
    def filename
      debug_name
    end
    
    def external_files
      return @external_files if @external_files
      @external_files= []
      
      target.include_projects.each { |ext|
        @external_files << ext.product_name(:debug, File.extname(filename)[1..-1])
      }
      @external_files
    end

  end
  
end