require 'distil/product/minified-product'

module Distil

  class CssProduct < MinifiedProduct
    
    extension "css"
    config_key "css"
    sort_order 0
    
    def initialize(settings, project)
      super(settings, project)
    end

    def get_debug_reference_for_file(file)
      path=file.relative_to_folder(source_folder)
      "@import url(\"#{path}\");"
    end
    
    # Javascript targets handle files that end in .js
    def handles_file?(file)
      ['.css'].include?(file.extension)
    end
    
    def minimise_product
  		# put each rule on its own line, and deletes @import statements
  		super.gsub(/\}/,"}\n").gsub(/.*@import url\(\".*\"\);/,'')
    end
    
  end

end
