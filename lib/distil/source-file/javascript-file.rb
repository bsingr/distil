module Distil

  JSL_IMPORT_REGEX= /\/\*jsl:import\s+([^\*]*)\*\//
  NIB_ASSET_REGEX= /(NIB\.asset(?:Url)?)\(['"]([^)]+)['"]\)/
  
  class JavascriptFile < SourceFile
    extension "js"
    content_type "js"

    def check_nib
      nib_name= basename(".js")
      unless content =~ /NIB\(\s*(['"])#{nib_name}\1/
        error "NIB name must match match filename, otherwise NIB will be unloadable."
      end

      Dir.glob("#{dirname}/**/*") { |asset|
        next if File.directory?(asset) || asset.to_s==full_path
        asset= project.file_from_path(asset)
        add_asset(asset)
        if ('html'==asset.content_type)
          project.add_alias_for_asset("#{nib_name}##{asset.basename}", asset)
        end
      }
    end
    
    def rewrite_content_relative_to_path(path)
      text= content.gsub(JSL_IMPORT_REGEX, '')
      text.gsub(NIB_ASSET_REGEX) do |match|
          asset= project.file_from_path(File.join(dirname, $2))
          if asset
            "#{$1}(\"#{asset.relative_path}\")"
          else
            match
          end
      end
    end
    
    def dependencies
      @dependencies unless @dependencies.nil?

      @dependencies= []
      
      lines= content.split("\n")
      line_num=0
      lines.each do |line|
        line_num+=1
      
        # handle dependencies
        line.scan(JSL_IMPORT_REGEX) do |match|
          import_file= File.join(dirname, $1)
          if (File.exists?(import_file))
            add_dependency project.file_from_path(import_file)
          else
            dependency= project.find_file($1, :js, :import)
            if (dependency)
              add_dependency project.file_from_path(dependency)
            else
              error "Missing import file: #{$1}", line_num
            end
          end
        end
        
        line.scan(NIB_ASSET_REGEX) do |match|
          asset= project.file_from_path(File.join(dirname, $1))
          if asset
            add_asset(asset)
          else
            error "Missing asset file: #{$1}", line_num
          end
        end
      end

      if full_path =~ /([^\.\/]+)\.jsnib\/\1\.js$/
        # Handle special asset requirements for NIB files
        check_nib
      else
        html= "#{basename(".js")}.html"
        html_path= File.join(dirname, html)
        
        # Add an alias for an HTML file with the same basename if it exists
        if File.exists?(html_path)
          asset= project.file_from_path(html_path)
          add_asset(asset)
          project.add_alias_for_asset(html, asset)
        end
      end
      
      @dependencies
    end
    
  end
  
end
