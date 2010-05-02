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

    def debug_content(options)
      destination= File.expand_path(options.remove_prefix||"")
      path= @file_path ? @file_path : self.relative_to_folder(destination)
      "loadScript(\"#{path}\");\n"
    end

  end

end
