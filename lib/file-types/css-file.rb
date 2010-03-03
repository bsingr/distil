class CssFile < SourceFile

  def self.extension
    ".css"
  end

  def debug_content(options)
    destination= File.expand_path(options.remove_prefix||"")
    "@import url(\"#{self.relative_to_folder(destination)}\");\n"
  end
  
end
