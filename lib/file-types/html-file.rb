class HtmlFile < SourceFile

  def self.extension
    ".html"
  end

  def minify_content(source)
    source.gsub(/>\s+</, "><")
  end
  
end
