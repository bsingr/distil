module Distil
  
  class Browser
    def supported?; true; end
    def setup ; end
    def open(url) ; end
    def teardown ; end

    def host
      require 'rbconfig'
      Config::CONFIG['host']
    end
  
    def macos?
      host.include?('darwin')
    end
  
    def windows?
      host.include?('mswin')
    end
  
    def linux?
      host.include?('linux')
    end

    def open(url)
      case
      when macos?
        `open #{url}`
      when windows?
        `start #{url}`
      else
        puts "I don't know how to open a browser for #{url} on your system"
      end
    end
  end

end
