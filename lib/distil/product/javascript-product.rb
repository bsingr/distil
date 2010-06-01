module Distil

  class JavascriptProduct < JavascriptBaseProduct
    include Concatenated

    extension "js"
    
    option :global_export, :aliases=>['export']
    option :additional_globals, [], :aliases=>['globals']
    
    def initialize(settings, target)
      super(settings, target)
      
      @options.global_export=target.name if true==global_export
    end

    def filename
      concatenated_name
    end

    def before_files(f)
      f.puts("/*#nocode+*/")
      f.puts(bootstrap_source) if bootstrap
      
      if global_export
        exports= [global_export, *additional_globals].join(", ")
        f.puts "(function(#{exports}){"
      end
    end
    
    def after_files(f)
      if global_export
        exports= ["window.#{global_export}={}", *additional_globals].join(", ")
        f.puts "})(#{exports});"
      end
      
      suffix= ""
      suffix << "\n\n/*#nocode-*/\n\n"
      if 0 < assets.length
        asset_references= assets.map { |a|
          content= target.get_content_for_file(a)
          content= content.gsub("\\", "\\\\").gsub("\n", "\\n").gsub("\"", "\\\"").gsub("'", "\\\\'")
          "\"#{target.alias_for_asset(a)}\": \"#{content}\""
        }

        suffix << <<-EOS
distil.module('#{target.name}', {
  folder: '',
  assets: {
    #{asset_references.join(",\n    ")}
  }
});
EOS
      end
      f.puts(suffix)
    end

    def can_embed_file?(file)
      ["html"].include?(file.content_type)
    end
    
  end

  class JavascriptMinifiedProduct < Product
    include Minified
    extension "js"
  end

  class JavascriptDebugProduct < JavascriptBaseProduct
    extension "js"
  
    def filename
      debug_name
    end

    def can_embed_file?(file)
      ["html"].include?(file.content_type)
    end
    
    def write_output
      return if up_to_date
      @up_to_date= true
      
      copy_bootstrap_script
      
      required_files= files.map { |file| "'#{relative_path(file)}'" }
      asset_files= assets.map { |file| "'#{target.alias_for_asset(file)}': '#{relative_path(file)}'" }
      
      target.project.external_projects.each { |ext|
        next if STRONG_LINKAGE!=ext.linkage
        
        debug_file= ext.product_name(:debug, "js")
        next if !File.exist?(debug_file)
        required_files.unshift("'#{relative_path(debug_file)}'")
      }
      
      File.open(filename, "w") { |f|
        f.write(target.notice_text)
        f.write("#{bootstrap_source}\n\n") if bootstrap
        files.each { |file|
          f.write("/*jsl:import #{relative_path(file)}*/\n")
        }
        f.write(<<-EOS)
distil.module('#{target.name}', {
  folder: '',
  required: [#{required_files.join(", ")}],
  asset_map: {
    #{asset_files.join(",\n    ")}
  }
});
EOS
      }

    end
    
  end

end
