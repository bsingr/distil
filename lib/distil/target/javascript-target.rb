module Distil

  class JavascriptTarget < Target
    option :bootstrap_source, "#{LIB_DIR}/js/bootstrap.js"
    option :bootstrap
    
    config_key "js"

    def initialize(settings, project)
      super(settings, project)
      @options.product_extension= "js"
      @options.join_string= "\n/*jsl:ignore*/;/*jsl:end*/\n"
      
      if bootstrap.nil?
        self.bootstrap= (APP_TYPE==project.project_type)
      end

      if (bootstrap)
        @options.content_prefix= "#{File.read(bootstrap_source)}\n\n/**#nocode+*/\n\n"
        @options.content_suffix= "\n\n/**#nocode-*/"
      else
        @options.content_prefix= "/**#nocode+*/\n\n"
        @options.content_suffix= "\n\n/**#nocode-*/"
      end
    end

    def get_debug_reference_for_file(file)
      file_path= file.full_path
      output_folder= project.output_folder
      path=file.relative_to_folder(source_folder) if 0==file_path.index(source_folder)
      path=file.relative_to_folder(output_folder) if 0==file_path.index(output_folder)
      "/*jsl:import #{path}*/\ndistil.queue(\"#{path}\");" 
    end
    
    # Javascript targets handle files that end in .js
    def handles_file?(file)
      ['.js'].include?(file.extension)
    end
    
  end

end
