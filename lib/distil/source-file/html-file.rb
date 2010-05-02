module Distil

  class HtmlFile < SourceFile

    extension ".html"
    content_type "html"

    def minify_content(source)
      source.gsub(/>\s+</, "><")
    end
  
  end

end