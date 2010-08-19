module Distil

  require "#{VENDOR_DIR}/pdoc/lib/pdoc"
  
  class PDocProduct < Product

    option :pdoc_template, "#{VENDOR_DIR}/pdoc-template"
    option :doc_folder, Interpolated, "$(path)/doc"

    extension "js"
    
    def filename
      File.join(doc_folder, 'index.html')
    end
    
    def write_output
      return if up_to_date
      @up_to_date= true

      PDoc.run({
        :source_files => files,
        :destination => doc_folder,
        :templates => pdoc_template,
        :syntax_highlighter => :pygments,
        :markdown_parser => :bluecloth,
        # :src_code_href => proc { |entity|
        #   "http://github.com/example/ex/#{entity.file}##{entity.line_number}"
        # },
        :pretty_urls => true,
        :bust_cache => true,
        :name => 'Example JavaScript Framework',
        :short_name => 'Ex',
        :home_url => 'http://example.com',
        :doc_url => 'http://example.com/api',
        :version => "1.2.0",
        :copyright_notice => 'This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/">Creative Commons Attribution-Share Alike 3.0 Unported License</a>.' 
      })
    end
    
  end
  
end
