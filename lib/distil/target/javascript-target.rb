module Distil

  class JavascriptTarget < Target
    
    config_key "js"

    def initialize(settings, project)
      super(settings, project)
      @options.product_extension= "js"
      @options.join_string= "\n/*jsl:ignore*/;/*jsl:end*/\n"
      @options.content_prefix= "/**#nocode+*/\n\n"
      @options.content_suffix= "\n\n/**#nocode-*/"
    end

    def get_debug_reference_for_file(file)
      file_path= file.full_path
      output_folder= project.output_folder
      path=file.relative_to_folder(source_folder) if 0==file_path.index(source_folder)
      path=file.relative_to_folder(output_folder) if 0==file_path.index(output_folder)
      "/*jsl:import #{path}*/\ndistil.load(\"#{path}\");" 
    end
    
    # Javascript targets handle files that end in .js
    def handles_file?(file)
      ['.js'].include?(file.extension)
    end
    
  end

end
