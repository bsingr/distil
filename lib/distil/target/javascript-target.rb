module Distil

  class JavascriptTarget < Target
    option :bootstrap_source, "#{ASSETS_DIR}/distil.js"
    option :bootstrap
    option :global_export, :aliases=>['export']
    option :additional_globals, [], :aliases=>['globals']
    
    config_key "js"
    sort_order 1
    
    def initialize(settings, project)
      super(settings, project)
      
      @lazy_bundles= 0

      @options.global_export=project.name if true==global_export
      
      @options.product_extension= "js"
      @options.join_string=<<-eos
        
        /*jsl:ignore*/;/*jsl:end*/
        
      eos
      
      if bootstrap.nil?
        self.bootstrap= (APP_TYPE==project.project_type)
      end
    end

    def bootstrap_script
      @bootstrap_script||=File.read(bootstrap_source).strip
    end
    
    def content_prefix(variant)
      prefix= ""
      prefix << "#{bootstrap_script}\n" if bootstrap
      prefix << "/**#nocode+*/\n\n#{bundle_definitions(variant)}\n\n"

      if :debug != variant && global_export
        exports= [global_export, *additional_globals].join(", ")
        prefix << "(function(#{exports}){\n\n"
      end
      return prefix
    end
    
    def content_suffix(variant)
      suffix=""
      
      if :debug != variant && global_export
        exports= ["window.#{global_export}={}", *additional_globals].join(", ")
        suffix << "})(#{exports});\n\n"
      end
      
      if :debug==variant || @lazy_bundles>0
        suffix << "distil.complete('#{project.name}');\n\n"
      end
      
      suffix << "/*#nocode-*/"
      suffix
    end

    def one_bundle_definition(project, variant)
      own_project= (project==self.project)
      
      folder= own_project ? "" : relative_path(project.output_folder)
      products= :debug==variant ? project.debug_products : project.products;
      required= []
      sources= []
      
      if (!own_project)
        product_files= products.map { |f| "'#{SourceFile.path_relative_to_folder(f, project.output_folder)}'" }
        required.concat(product_files)
      end
      
      return <<-eos

        distil.module('#{project.name}', {
          folder: '#{folder}',
          required: [#{required.join(',')}]
        });
      eos
    end
    
    def bundle_definitions(variant)
      bundles= ""
      project.external_projects.each { |p|
        next if LAZY_LINKAGE!=p.linkage
        @lazy_bundles+=1
        bundles << one_bundle_definition(p, variant)
      }
      return bundles if :debug!=variant && bundles.empty?
      bundles << one_bundle_definition(project, variant)
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
      return <<-eos
        /*jsl:import #{path}*/
        distil.queue("#{project.name}", "#{path}");
      eos
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
