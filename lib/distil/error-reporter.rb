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
    
    def has_errors
      @@error_count > 0
    end

    def self.error(message, file=nil, line_number=nil)
      @@error_count+=1

      case when file && line_number
        puts "#{file}:#{line_number}: error: #{message}"
      when file
        puts "#{file}: error: #{message}"
      else
        puts "error: #{message}"
      end
    end
    
    def error(message, file=nil, line_number=nil)
      ErrorReporter.error(message, file, line_number)
    end

    def self.warning(message, file=nil, line_number=nil)
      @@warning_count+=1
      return if (ignore_warnings)
      case when file && line_number
        puts "#{file}:#{line_number}: warning: #{message}"
      when file
        puts "#{file}: warning: #{message}"
      else
        puts "warning: #{message}"
      end
    end

    def warning(message, file=nil, line_number=nil)
      ErrorReporter.warning(message, file, line_number)
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


