module Distil

  COMPRESSOR= File.expand_path("#{VENDOR_DIR}/yuicompressor-2.4.2.jar")
  
  class ConcatenateTask < Task
    
    option :join_string, "\n", :aliases=>['join']
    option :content_prefix, :aliases=>['prefix']
    option :content_suffix, :aliases=>['suffix']

    option :import_name
    option :concatenated_name
    option :debug_name
    option :minified_name
    option :compressed_name
    
    option :minify
    option :compress
    option :product_extension
    
    def products
      @products if @products
      @products= [concatenated_name, debug_name]
      @products << minified_name if minify
      @products << compressed_name if compress
    end

    def minify_product
    	# Run the Y!UI Compressor
    	buffer= ""
  	
    	IO.popen("java -jar #{COMPRESSOR} #{concatenated_name}", "r+") { |pipe|
    	  pipe.close_write
    	  buffer= pipe.read
  	  }
  	  
      # buffer = `java -jar #{$compressor} --type #{type} #{working_file}`
    	if ('css'==product_extension)
    		# puts each rule on its own line, and deletes @import statements
    		return buffer.gsub(/\}/,"}\n").gsub(/.*@import url\(\".*\"\);/,'')
    	else
    		return buffer
    	end
    end
    
    def process_files(files)
      products.each { |file|
        next if !File.exist?(file)
        File.delete(file)
      }

      concat_files= []
      debug_files= []
      
      target.project.external_projects.each { |project|
        next if INCLUDE_LINKAGE!=project.linkage
        
        concat_file= Interpolated.value_of(project.concatenated_name, self)
        debug_file= Interpolated.value_of(project.import_name, self)

        next if !File.exist?(concat_file) || !File.exist?(debug_file)

        concat_files << SourceFile.from_path(concat_file)
        debug_files << SourceFile.from_path(debug_file)
      }

      concat_files.concat(files)
      debug_files.concat(files)
    
      File.open(concatenated_name, "w") { |f|
        f.write(target.notice_text)
        f.write(content_prefix)
        concat_files.each_with_index { |file, i|
          f.write(join_string) if i>0
          f.write(target.get_content_for_file(file))
        }
        f.write(content_suffix)
      }

      File.open(debug_name, "w") { |f|
        f.write(target.notice_text)
        f.write(content_prefix)
        debug_files.each { |file|
          f.write("\n")
          f.write(target.get_debug_reference_for_file(file))
        }
        f.write(content_suffix)
      }
      
      return if !minify && !compress
      
      minified= minify_product
      
      if (minify)
        File.open(minified_name, "w") { |f|
          f.write(minified)
        }
      end
      
      if (compress)
        Zlib::GzipWriter.open(compressed_name) { |f|
          f.write(minified)
        }
      end
          
    end
    
  end
  
end
