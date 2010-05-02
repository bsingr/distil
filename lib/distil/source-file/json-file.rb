require "distil/source-file/javascript-file"

module Distil
  
  class JsonFile < JavascriptFile
    
    extension '.json'
  
    def minify_content(source)
      super("(#{source})")[1..-3]
    end
  
  end
  
end