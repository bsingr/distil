module Distil
  
  class MinifiedProduct < Product
    
    def minify_product
    	# Run the Y!UI Compressor
    	buffer= ""
  	
    	IO.popen("java -jar #{COMPRESSOR} #{concatenated_name} -o #{minified_name}", "r+") { |pipe|
    	  pipe.close_write
    	  buffer= pipe.read
  	  }
  	  
  	  buffer
    end
  
  end

end