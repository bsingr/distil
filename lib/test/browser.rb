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
  
  def applescript(script)
    raise "Can't run AppleScript on #{host}" unless macos?
    system "osascript -e '#{script}' 2>&1 >/dev/null"
  end
end

class FirefoxBrowser < Browser
  def initialize(path=File.join(ENV['ProgramFiles'] || 'c:\Program Files', '\Mozilla Firefox\firefox.exe'))
    @path = path
  end

  def visit(url)
    system("open -a \"Firefox 3.5.app\" '#{url}'") if macos?
    system("#{@path} #{url}") if windows? 
    system("firefox #{url}") if linux?
  end

  def to_s
    "Firefox"
  end
end

class SafariBrowser < Browser
  def supported?
    macos?
  end
  
  def setup
    applescript('tell application "Safari" to make new document')
  end
  
  def visit(url)
    applescript('tell application "Safari" to set URL of front document to "' + url + '"')
  end

  def teardown
    #applescript('tell application "Safari" to close front document')
  end

  def to_s
    "Safari"
  end
end

class IEBrowser < Browser
  def setup
    require 'win32ole' if windows?
  end

  def supported?
    windows?
  end
  
  def visit(url)
    if windows?
      ie = WIN32OLE.new('InternetExplorer.Application')
      ie.visible = true
      ie.Navigate(url)
      while ie.ReadyState != 4 do
        sleep(1)
      end
    end
  end

  def to_s
    "Internet Explorer"
  end
end

$browsers= {
  "safari" => SafariBrowser,
  "firefox" => FirefoxBrowser,
  "ie" => IEBrowser
}
