module Distil

  begin
    require 'pdoc'
  rescue LoadError
    require File.join(VENDOR_DIR, "pdoc", "lib", "pdoc")
  end
  
  class PDocProduct < Product

    # option :jsdoc_conf, "#{LIB_DIR}/jsdoc.conf"
    # option :jsdoc_template, "#{VENDOR_DIR}/jsdoc-extras/templates/coherent"
    # option :jsdoc_plugins, "#{VENDOR_DIR}/jsdoc-extras/plugins"
    option :doc_folder, Interpolated, "$(path)/doc"

    extension "js"
    
    def filename
      File.join(doc_folder, 'index.html')
    end
    
    def write_output
      return if up_to_date
      @up_to_date= true
      
      doc_files= []
      
      files.each { |f|
        next if !handles_file?(f)
        p= f.file_path || f.to_s
        doc_files << p
      }

      FileUtils.mkdir_p(doc_folder)
      
      PDoc.run({
        :source_files => doc_files,
        :destination => doc_folder,
        :generator => PDoc::Generators::Pythonesque,
        :index_page => 'README.markdown',
        # :syntax_highlighter => syntax_highlighter,
        # :markdown_parser => :bluecloth,
        :src_code_href => proc { |obj|
          "http://github.com/sstephenson/prototype/blob/#{hash}/#{obj.file}#LID#{obj.line_number}"
        },
        :pretty_urls => false,
        :bust_cache => false,
        :name => 'Prototype JavaScript Framework',
        :short_name => 'Prototype',
        :home_url => 'http://prototypejs.org',
        :version => target.version,
        # :index_header => index_header,
        :footer => 'This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/">Creative Commons Attribution-Share Alike 3.0 Unported License</a>.',
        :assets => 'doc_assets'
      })

      
    end
    
  end
  
end
