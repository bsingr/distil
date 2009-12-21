class HtmlFile < SourceFile

  def self.extension
    ".html"
  end

  def can_embed_as_content
    true
  end

end
