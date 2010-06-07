module Distil

  class CssFile < SourceFile

    extension "css"
    content_type "css"

    def minified_content(source)
      super(source).gsub(/\}/,"}\n").gsub(/.*@import url\(\".*\"\);/,'')
    end

  end

end
