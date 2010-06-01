module Distil
  
  class NibTask < Task
    include ErrorReporter
    
    def find_files
      nibs= @extras["nibs"]
      return [] if !nibs
      
      extra_files=[]
      
      nibs.each { |n|
        case
          when n.is_a?(String)
            nib_name= File.basename(n, ".jsnib")
            nib_folder= File.join([target.source_folder, n].compact)

            Dir.glob("#{nib_folder}/**/*.{jsnib,js,json,css,html}") { |file|
              source_file= SourceFile.from_path(file)
              extra_files << source_file
              target.set_alias_for_asset("#{nib_name}##{source_file.relative_to_folder(nib_folder)}", source_file)
            }
          else
            puts "Unknown nib entry: #{n.inspect}"
        end
      }
      
      extra_files
    end
    
  end
  
end
