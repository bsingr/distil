module Distil
  
  class JavascriptBaseProduct < Product
    option :bootstrap_script, "#{ASSETS_DIR}/distil.js"
    option :bootstrap

    def initialize(settings, target)
      super(settings, target)
      
      @join_string=<<-eos
        
        /*jsl:ignore*/;/*jsl:end*/
        
      eos
      
      if bootstrap.nil?
        self.bootstrap= (APP_TYPE==target.target_type)
      end
    end

    def bootstrap_source
      @bootstrap_source||=File.read(bootstrap_script).strip
    end
    
    def copy_bootstrap_script
      FileUtils.cp bootstrap_script, target.project.output_folder if !bootstrap
    end
    
  end
  
end
