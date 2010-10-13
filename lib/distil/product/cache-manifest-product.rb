module Distil
  
  class CacheManifestProduct < Product
    content_type "manifest"
    variants [RELEASE_VARIANT]
    
    def build
      FileUtils.mkdir_p(File.dirname(output_path))
      File.open(output_path, "w") { |output|
        output.puts "CACHE MANIFEST"
        output.puts "# generated @ #{Time.new.rfc2822}"
        output.puts
        project.assets.each { |a|
          output.puts project.relative_output_path_for(a)
        }
      }
    end
    
  end
  
end