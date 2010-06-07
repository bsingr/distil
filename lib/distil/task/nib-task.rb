module Distil

  NIB_ASSET_REGEX= /(NIB\.asset(?:Url)?)\(['"]([^)]+)['"]\)/
  
  class NibTask < Task
    include ErrorReporter

    def handles_file(file)
      return ["js"].include?(file.content_type)
    end

    def preprocess_file(nib_name, nib_folder, file)
      return if !handles_file(file)

      content= target.get_content_for_file(file).split("\n")
    
      line_num=0
    
      content.each { |line|
      
        line_num+=1
      
        # handle dependencies
        line.gsub!(NIB_ASSET_REGEX) { |match|
          asset_file= File.expand_path(File.join(file.parent_folder, $2))
          asset_file= SourceFile.from_path(asset_file)
          if (!File.exists?(asset_file))
            file.warning "Asset not found: #{$2} (#{asset_file})", line_num
            "#{$0}"
          else
            "#{$1}(\"#{asset_file.relative_to_folder(target.source_folder)}\")"
            # "#{$1}(\"#{nib_name}##{asset_file.relative_to_folder(nib_folder)}\")"
          end
        }
      
      }
    
      target.set_content_for_file(file, content.join("\n"))
    end
    
    def include_file(file)

      return if !File.fnmatch("**/*.jsnib/*.js", file)
      # puts "Nib asset: #{file}"
      match= file.to_s.match(/([^\.\/]+).jsnib\/(.*)\.js/)
      return if match[1]!=match[2]

      nib_name= match[1]
      nib_folder= File.dirname(file)

      preprocess_file(nib_name, nib_folder, file)
      
      
      # Found main js file inside the JSNib add assets for all the other files
      target.set_alias_for_asset("#{match[1]}##{match[2]}", file)
      Dir.glob("#{File.dirname(file)}/**/*") { |asset|
        next if File.directory?(asset) || asset.to_s==file.to_s
        
        asset= SourceFile.from_path(asset)
        preprocess_file(nib_name, nib_folder, asset)
        file.add_asset(asset)
        
        if 'html'==asset.content_type
          target.set_alias_for_asset("#{nib_name}##{asset.relative_to_folder(nib_folder)}", asset)
        end
      }
      
    end
    
  end
  
end
