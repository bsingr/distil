module Distil
  
  class JavascriptFile < SourceFile
    extension '.js'
    content_type 'js'
    
    def can_embed_as_content(file)
      [".css", ".html", ".json"].include?(file.extension)
    end

    def escape_embeded_content(content)
      content.gsub("\\", "\\\\").gsub("\n", "\\n").gsub("\"", "\\\"").gsub("'", "\\\\'")
    end

  end

end
