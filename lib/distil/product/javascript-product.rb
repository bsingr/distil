module Distil

  class JavascriptProduct < JavascriptBaseProduct
    include Concatenated

    extension "js"
    
    option :global_export
    option :additional_globals, [], :aliases=>['globals']
    
    def before_externals(f)
      f.puts("/*#nocode+*/")
      f.puts(bootstrap_source) if bootstrap
    end

    def after_externals(f)
    end
    
    def before_files(f)

      if 0 != assets.length
        asset_references= []
        asset_map= []
        assets.each { |a|
          if can_embed_file?(a)
            next if @files.include?(a)
            content= a.minified_content(target.get_content_for_file(a))
            content= content.gsub("\\", "\\\\").gsub("\n", "\\n").gsub("\"", "\\\"").gsub("'", "\\\\'")
            asset_references << "\"#{target.alias_for_asset(a)}\": \"#{content}\""
          else
            asset_alias= target.alias_for_asset(a)
            asset_path= relative_path(a)
            next if asset_alias==asset_path
            asset_map << "'#{asset_alias}': '#{asset_path}'" 
          end
        }

        f << <<-EOS
        
distil.module('#{target.name}', {
  folder: '',
  asset_map: {
    #{asset_map.join(",\n    ")}
  },
  assets: {
    #{asset_references.join(",\n    ")}
  }
});


EOS
      end

      if global_export
        exports= [global_export, *additional_globals].join(", ")
        f.puts "(function(#{exports}){"
      end
    end
    
    def after_files(f)
      if global_export
        exports= ["window.#{global_export}=window.#{global_export}||{}", *additional_globals].join(", ")
        f.puts "})(#{exports});"
      end

      f.puts "\n\n/*#nocode-*/\n\n"
      
      f.puts "distil.kick();" if bootstrap
      
    end
    
  end

  class JavascriptMinifiedProduct < Product
    include Minified
    extension "js"
  end

  class JavascriptDebugProduct < JavascriptBaseProduct
    include Debug
    extension "js"

    option :global_export
    option :synchronous_load, false, :aliases=>['sync']
  
    def write_output
      return if up_to_date
      @up_to_date= true
      
      copy_bootstrap_script
      
      required_files= files.map { |file| "'#{relative_path(file)}'" }
      asset_map= []
      assets.each { |a|
        asset_alias= target.alias_for_asset(a)
        asset_path= relative_path(a)
        next if asset_alias==asset_path
        asset_map << "'#{asset_alias}': '#{asset_path}'" 
      }
      
      external_files.each { |ext|
        next if !File.exist?(ext)
        required_files.unshift("'#{relative_path(ext)}'")
      }
      
      File.open(filename, "w") { |f|
        f.write(target.notice_text)
        f.write("#{bootstrap_source}\n\n") if bootstrap
        
        if global_export
          f.write("window.#{global_export}=window.#{global_export}||{};");
          f.write("\n\n");
        end
        
        files.each { |file|
          f.write("/*jsl:import #{relative_path(file)}*/\n")
        }
        
        if (APP_TYPE==target.target_type && synchronous_load)
          f.puts "distil.sync= #{Kernel::Boolean(synchronous_load)};"
        end
        
        f.write(<<-EOS)

distil.module('#{target.name}', {
  folder: '',
  required: [#{required_files.join(", ")}],
  asset_map: {
    #{asset_map.join(",\n    ")}
  }
});
EOS
      }

    end
    
  end

end
