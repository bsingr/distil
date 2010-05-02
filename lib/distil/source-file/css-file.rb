module Distil

  class CssFile < SourceFile

    extension ".css"
    content_type "css"

    def minify_content(source)
      super(source).gsub(/\}/,"}\n").gsub(/.*@import url\(\".*\"\);/,'')
    end

    def debug_content(options)
      destination= File.expand_path(options.remove_prefix||"")
      "@import url(\"#{self.relative_to_folder(destination)}\");\n"
    end
  
  end

end
