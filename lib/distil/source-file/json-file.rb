require "distil/source-file/javascript-file"

module Distil
  
  class JsonFile < JavascriptFile
    
    extension '.json'
  
    def minified_content(source)
      super("(#{source})")[1..-3]
    end
  
  end
  
end