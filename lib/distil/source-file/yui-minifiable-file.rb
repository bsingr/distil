module Distil
  module YuiMinifiableFile
    
    def minified_content(source=content)
    	# Run the Y!UI Compressor
      return source if !content_type
    	buffer= ""
    
    	IO.popen("java -jar #{COMPRESSOR} --type #{content_type}", "r+") { |pipe|
    	  pipe.puts(source)
    	  pipe.close_write
    	  buffer= pipe.read
  	  }
	  
      buffer
    end

  end
end