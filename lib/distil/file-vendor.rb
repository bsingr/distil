module Distil
  
  module FileVendor
    
    def cache_file(file)
      @file_cache={} if @file_cache.nil?
      @file_cache[file.full_path]= file
    end
    
    def file_from_path(filepath)
      return if !filepath
      @file_cache={} if @file_cache.nil?
      full_path= File.expand_path(filepath)
      file= @file_cache[full_path]
      return file if file
    
      extension= File.extname(filepath)[1..-1]
    
      SourceFile.subclasses.each { |handler|
        next if (handler.extension != extension)
        return handler.new(filepath, self)
      }
    
      return SourceFile.new(filepath, self)
    end

  end
  
end