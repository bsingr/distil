module Distil
  
  class HtmlFile < SourceFile
    extension "html"
    content_type "html"

    def minified_content(source=content)
      source.gsub(/>\s+</, "><")
    end
  end
  
end
    