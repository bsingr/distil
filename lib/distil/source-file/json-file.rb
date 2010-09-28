require "distil/source-file/javascript-file"

module Distil
  
  class JsonFile < JavascriptFile
    
    extension 'json'
    content_type 'js'
    
    def minified_content
      super("(#{content})")[1..-3]
    end
  
  end
  
end
