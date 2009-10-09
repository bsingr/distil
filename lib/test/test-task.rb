#######
# NOT READY FOR USE
#######


require 'webrick'
require "#{$script_dir}/browser.rb"

include WEBrick

$unit_test_html= File.read("#{$script_dir}/unittest.html")
$script_wrapper_html= File.read("#{$script_dir}/scriptwrapper.html")

$js_task_options= {
  "name" => "test",
  "output-folder" => ".",
  "include-all-files" => true
}

def relative_path(file, output_folder)
	outputFolder= File.expand_path(output_folder).to_s
	file= File.expand_path(file).to_s
	
	# Remove leading slash and split into parts
	file_parts= file.slice(1..-1).split('/');
	output_parts= outputFolder.slice(1..-1).split('/');

	common_prefix_length= 0

	file_parts.each_index { |i|
		common_prefix_length= i
		break if file_parts[i]!=output_parts[i]
	}

	return '../'*(output_parts.length-common_prefix_length) + file_parts[common_prefix_length..-1].join('/')
end


#  Create an HTML wrapper file for a JavaScript file. The wrapper will include
#  one script tag for each imported file in the script. This means you don't
#  have to write lots of silly wrapper HTML files for your tests.
def html_wrapper_for_script_file(script_file)
  options= Task.options({}.merge($js_task_options))

  js= JsTask.new("test", options)
  js.include_file(script_file)
  
  files= js.order_files
  
  current_dir= File.expand_path('.')

  files.map! { |file|
    file= file.gsub(/-uncompressed\.js/, '-debug.js')
    relative_path(file, current_dir)
  }
    
  scripts= files.map { |file|
    "<script src=\"#{file}\" type=\"text/javascript\" charset=\"utf-8\"></script>"
  }
  
  replace_tokens($script_wrapper_html, {
            "scripts" => scripts.join("\n"),
            "title" => script_file
          })
end

class ScriptWrapper < HTTPServlet::AbstractServlet

  def do_GET(request, response)
    response.status = 200
    response['Content-Type'] = 'text/html'
    
    file= request.query.to_s
    response.body = html_wrapper_for_script_file(file)
  end

end  

class WEBrick::HTTPServlet::AbstractServlet
  def prevent_caching(res)
    res['ETag'] = nil
    res['Last-Modified'] = Time.now + 100**4
    res['Cache-Control'] = 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0'
    res['Pragma'] = 'no-cache'
    res['Expires'] = Time.now - 100**4
  end
end

class NonCachingFileHandler < WEBrick::HTTPServlet::FileHandler
  def do_GET(req, res)
    super
    set_default_content_type(res, req.path)
    prevent_caching(res)
  end
  
  def set_default_content_type(res, path)
    res['Content-Type'] = case path
      when /\.js$/ then 'text/javascript'
      when /\.html$/ then 'text/html'
      when /\.css$/ then 'text/css'
      else 'text/plain'
    end
  end
end

class BrowserTestServlet < HTTPServlet::AbstractServlet
  
  def initialize(server, browser_test)
    super(server)
    @browser_test= browser_test
  end
  
  def generate_file(filename)
    params= {
      'file'=>filename
    }
    return replace_tokens($unit_test_html, params)
  end
  
  def do_GET(request, response)
    prevent_caching(response)
    
    file= request.query.to_s
    if ("first_file"==file)
      response.status= 302
      response['Location']= @browser_test.next_file
      response.body= "Forwarded..."
      return
    end
    
    response.status = 200
    response['Content-Type'] = 'text/html'
    response.body = $unit_test_html
  end

  def do_POST(request, response)
    prevent_caching(response)
    q= request.query
    
    failures= []
    
    q['failures'].split('~!~').each { |line|
      failures << "#{line}"
    }
    
    location= @browser_test.send_results({
        'failures' => failures,
        'passed' => q['numberOfPasses'].to_i,
        'failed' => q['numberOfFailures'].to_i,
        'skipped' => q['numberOfSkipped'].to_i
      })
    
    response.status= 302
    response['Location']= location
    response.body="Redirected..."
  end
  
end

class TestTask < Task
  
  declare_option :browsers, ['safari']
  
  def initialize(section, options)
    super(section, options)
    @result_queue= Queue.new
    @file_queue= Queue.new
    
    @passed= 0
    @failed= 0
    @skipped= 0
  end

  def self.task_name
    # Disable tests by not returning a  name
    # "test"
  end

  def handles_file?(file_name)
    file_name[/\.js$/] || file_name[/\.html$/]
  end

  def start_webserver()
    access_log_stream = File.open('/dev/null', 'w')
    access_log = [[access_log_stream, AccessLog::COMBINED_LOG_FORMAT]]
  
    @server = HTTPServer.new(:Port=>8000, :Logger=>Log.new(nil, BasicLog::WARN),
                 :AccessLog=>[])
  
    @server.mount "/wrapped", ScriptWrapper
    @server.mount "/", NonCachingFileHandler, "."
  
    trap "INT" do @server.shutdown end
    t= Thread.new { @server.start }
  end
  
  def next_file()
    file= @file_queue.pop
    file= relative_path(file, Dir.getwd)
    
    if (file[/\.js$/])
      file= "/wrapped?#{file}"
    end
    return file
  end
  
  def send_results(results)
    @result_queue.push(results)
    next_file
  end
  
  def process_all_files()
    order_files
    
    return if (0==@ordered_files.length)
    
    start_webserver
    @server.mount "/unittest", BrowserTestServlet, self

    browsers= @options.browsers.map { |b| "#{b}".downcase }
    
    browsers.each { |b|
      browser= ($browsers[b]).new
      next if !browser.supported?

      browser.setup
      browser.visit("http://localhost:8000/unittest")
    
      @ordered_files.each { |f|

        @file_queue.push(f)
        status= @result_queue.pop
      
        file= File.expand_path(f)

        @passed= status['passed']
        @failed= status['failed']
        @skipped= status['skipped']

        status['failures'].each { |line|
          puts "#{file}: #{line}"
        }

      }
    
      # release waiting call to send_results
      @file_queue.push('about:blank');

      puts "#{b}: #{@passed} passed #{@failed} failed #{@skipped} skipped\n"
    }
    
    @server.unmount "/unittest"
    @server.shutdown
  end
  
end
