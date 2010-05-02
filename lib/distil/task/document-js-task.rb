module Distil

  JSDOC_COMMAND= "#{VENDOR_DIR}/jsdoc-toolkit/jsrun.sh"
  
  class DocumentJsTask < Task

    option :jsdoc_conf, "#{LIB_DIR}/jsdoc.conf"
    option :jsdoc_template, "#{VENDOR_DIR}/jsdoc-extras/templates/coherent"
    option :jsdoc_plugins, "#{VENDOR_DIR}/jsdoc-extras/plugins"
    option :doc_folder, Interpolated, "$(path)/doc"

    def handles_file(file)
      ["js"].include?(file.content_type)
    end
    
    def products
      return [] if !target.generate_docs
      [File.join(doc_folder, 'index.html')]
    end
    
    def document_files(files)

      return if (!File.exists?(JSDOC_COMMAND))

      tmp= Tempfile.new("jsdoc.conf")
    
      template= File.read(jsdoc_conf)
      doc_files= []
      
      files.each { |f|
        next if !handles_file(f)
        p= f.file_path || f.to_s
        doc_files << "\"#{p}\""
      }

      conf= replace_tokens(template, {
                      "DOC_FILES"=>doc_files.join(",\n"),
                      "DOC_OUTPUT_DIR"=>doc_folder,
                      "DOC_TEMPLATE_DIR"=>jsdoc_template,
                      "DOC_PLUGINS_DIR"=>jsdoc_plugins
                  })

      tmp << conf
      tmp.close()
    
      command= "#{JSDOC_COMMAND} -c=#{tmp.path}"
    
      stdin, stdout, stderr= Open3.popen3(command)
      stdin.close
      output= stdout.read
      errors= stderr.read

      tmp.delete
    
      puts errors
      puts output
      
    end
    
  end
  
end
