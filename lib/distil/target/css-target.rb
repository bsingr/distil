module Distil

  class CssTarget < Target
    
    config_key "css"
    sort_order 0
    
    def initialize(settings, project)
      super(settings, project)
      @options.product_extension= "css"
    end

    def get_debug_reference_for_file(file)
      path=file.relative_to_folder(source_folder)
      "@import url(\"#{path}\");"
    end
    
    # Javascript targets handle files that end in .js
    def handles_file?(file)
      ['.css'].include?(file.extension)
    end
    
  end

end
