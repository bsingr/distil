class FileReferenceFilter < Filter

  def file_reference(file)
    "{{FILEREF(#{file})}}"
  end
  
  def content_reference(file)
    "{{CONTENTREF(#{file})}}"
  end

  def filter_content(file, content, options)
    destination= File.expand_path(options.remove_prefix||"")
    
    content.gsub!(/\{\{FILEREF\(([^)]*)\)\}\}/) { |match|
      include_file= SourceFile.from_path($1)
      include_file.relative_to_folder(destination)
    }

    content.gsub!(/\{\{CONTENTREF\(([^)]*)\)\}\}/) { |match|
      include_file= SourceFile.from_path($1)
      included_content= include_file.filtered_content(options)
      included_content= include_file.minify_content(included_content)
      file.escape_embeded_content(included_content)
    }

    content
  end

  
end
