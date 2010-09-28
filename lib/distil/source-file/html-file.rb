module Distil
  
  class HtmlFile < SourceFile
    extension "html"
    content_type "html"

    def minified_content
      content.gsub(/>\s+</, "><")
    end
  end
  
end
    