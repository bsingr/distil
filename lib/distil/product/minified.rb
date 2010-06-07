module Distil

  COMPRESSOR= File.expand_path("#{VENDOR_DIR}/yuicompressor-2.4.2.jar")
    
  module Minified
    
    def filename
      minified_name
    end
    
    def external_files
      []
    end
    
    def write_output
      return if up_to_date
      @up_to_date= true
      
    	# Run the Y!UI Compressor
    	system "java -jar #{COMPRESSOR} #{concatenated_name} -o #{filename}"
    	
    	if 'css'==extension
    		buffer= File.read(filename)
    		File.open(filename, "w") { |f|
    		  f.write(buffer.gsub(/\}/,"}\n").gsub(/.*@import url\(\".*\"\);/,''))
  		  }
      end 
    end
  
  end

end