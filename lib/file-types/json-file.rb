require "#{$script_dir}/file-types/javascript-file.rb"

class JsonFile < JavascriptFile

  def self.extension
    ".json"
  end

  def minify_content(source)
    super("(#{source})")[1..-3]
    
  end
  
end