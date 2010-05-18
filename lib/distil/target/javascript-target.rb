module Distil

  class JavascriptTarget < Target
    option :bootstrap_source, "#{LIB_DIR}/js/distil.js"
    option :bootstrap
    
    config_key "js"
    sort_order 1
    
    def initialize(settings, project)
      super(settings, project)
      @options.product_extension= "js"
      @options.join_string= "\n/*jsl:ignore*/;/*jsl:end*/\n"
      
      if bootstrap.nil?
        self.bootstrap= (APP_TYPE==project.project_type)
      end
      
      if (bootstrap)
        @options.content_prefix= "#{File.read(bootstrap_source)}\n\n/**#nocode+*/\n\n#{bundle_definitions}"
        @options.content_suffix= "\n\ndistil.kick();\n\n/**#nocode-*/"
      else
        @options.content_prefix= "/**#nocode+*/\n\n"
        @options.content_suffix= "\n\n/**#nocode-*/"
        @options.content_suffix= "\n\ndistil.kick();\n\n/**#nocode-*/"
      end
    end

    def one_bundle_definition(project)
      folder= ""
      folder= relative_path(project.output_folder) if project!=self.project
      debug_files= project.debug_products.map { |f| "'#{relative_path(f)}'" }
      release_files= project.release_products.map { |f| "'#{relative_path(f)}'" }

      "
      distil.bundle('#{project.name}', {
        folder: '#{folder}',
        required: {
          en_debug: [#{debug_files.join(',')}],
          en: [#{release_files.join(',')}]
        }
      });
      "
    end
    
    def bundle_definitions
      bundles= one_bundle_definition(project)
      
      project.external_projects.each { |p|
        next if LAZY_LINKAGE==p.linkage
        bundles << one_bundle_definition(p)
      }
      bundles
    end
    
    def relative_path(file)
      file=SourceFile.from_path(file) if file.is_a?(String)
      
      file_path= file.full_path
      output_folder= project.output_folder
      
      path=file.relative_to_folder(source_folder) if 0==file_path.index(source_folder)
      path=file.relative_to_folder(output_folder) if 0==file_path.index(output_folder)
      path
    end
    
    def get_debug_reference_for_file(file)
      path= relative_path(file)
      "/*jsl:import #{path}*/\ndistil.queue(distil.SCRIPT_TYPE, \"#{path}\");" 
    end
    
    # Javascript targets handle files that end in .js
    def handles_file?(file)
      ['.js'].include?(file.extension)
    end

    def build_assets
      super
      FileUtils.cp bootstrap_source, project.output_folder if !bootstrap
    end
    
  end

end
