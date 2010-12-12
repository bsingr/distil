module Distil
  
  class HtmlProduct < Product
    content_type "html"
    variants [RELEASE_VARIANT]
    
    def build
      folder= File.dirname(output_path)
      FileUtils.mkdir_p(folder)
      
      files.each { |f|
        product_path= File.join(folder, File.basename(f))
        FileUtils.rm product_path if File.exists? product_path
        File.symlink f.path_relative_to(folder), product_path
      }
    end
    
  end
  
end