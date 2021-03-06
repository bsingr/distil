module Distil
  module ErrorReporter
    
    @@warning_count=0
    @@error_count=0
    @@ignore_warnings= false
    @@total_warning_count=0
    @@total_error_count=0
    
    def ignore_warnings
      @@ignore_warnings
    end
    
    def ignore_warnings=(ignore)
      @@ignore_warnings=ignore
    end
    
    def total_error_count
      @@total_error_count
    end
    
    def total_warning_count
      @@total_warning_count
    end
    
    def self.error(message, file=nil, line_number=nil)
      @@error_count+=1
      if (file && line_number)
        printf("%s:%d: error: %s\n", file, line_number, message)
      else
        printf("error: %s\n", message)
      end
    end
    
    def error(message, file=nil, line_number=nil)
      @@error_count+=1
      if (file && line_number)
        printf("%s:%d: error: %s\n", file, line_number, message)
      else
        printf("error: %s\n", message)
      end
    end

    def self.warning(message, file=nil, line_number=nil)
      @@warning_count+=1
      return if (ignore_warnings)
      if (file && line_number)
        printf("%s:%d: warning: %s\n", file, line_number, message)
      else
        printf("warning: %s\n", message)
      end
    end

    def warning(message, file=nil, line_number=nil)
      @@warning_count+=1
      return if (ignore_warnings)
      if (file && line_number)
        printf("%s:%d: warning: %s\n", file, line_number, message)
      else
        printf("warning: %s\n", message)
      end
    end
    
    def report
      puts "\n" if (@@error_count>0 || @@warning_count>0)
      puts "#{@@error_count} error(s), #{@@warning_count} warning(s)#{ignore_warnings ? " ignored" : ""}"
      @@total_error_count += @@error_count
      @@total_warning_count += @@warning_count
      @@error_count=0
      @@warning_count=0
    end
    
  end
  
end


