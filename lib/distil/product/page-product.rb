module Distil

  class PageProduct < Product
    extension "html"

    def filename
      File.join(target.project.output_folder, "index.html")
    end
      
    def write_output
      output_folder= target.project.output_folder
      mode= target.project.mode
      
      files.each { |f|
        if (RELEASE_MODE==mode)
          FileUtils.cp f, output_folder
        else
          product_path= File.join(output_folder, File.basename(f))
          FileUtils.rm product_path if File.exists? product_path
          File.symlink f.relative_to_folder(output_folder), product_path
        end
      }
    end

  end
  
end
