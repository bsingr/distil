module Distil

  JSL_IMPORT_REGEX= /\/\*jsl:import\s+([^\*]*)\*\//
  NIB_ASSET_REGEX= /(NIB\.asset(?:Url)?)\(['"]([^)]+)['"]\)/
  NIB_DECLARATION_REGEX= /NIB\(\s*(["'])(\w(?:\w|-)*)\1\s*,/
  
  class JavascriptFile < SourceFile
    include YuiMinifiableFile

    extension "js"
    content_type "js"

    def check_nib
      nib_name= basename(".js")

      Dir.glob("#{dirname}/**/*") { |asset|
        next if File.directory?(asset) || asset.to_s==full_path
        asset= project.file_from_path(asset)

        case
        when 'js'==asset.content_type || 'css'==asset.content_type
          add_dependency(asset)
        when 'html'==asset.content_type
          add_asset(asset)
          project.add_alias_for_asset("#{nib_name}##{asset.basename}", asset)
        else
          add_asset(asset)
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
      is_nib_file= (full_path =~ /([^\.\/]+)\.jsnib\/\1\.js$/)
      
      content.each_with_index do |line, line_num|
        line_num+=1
      
        if is_nib_file && match=line.match(NIB_DECLARATION_REGEX)
          unless match[2]==basename(".*")
            error "NIB name must match match filename, otherwise NIB will be unloadable.", line_num
          end
        end
        
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

      if is_nib_file
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
