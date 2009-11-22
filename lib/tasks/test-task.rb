#######
# NOT READY FOR USE
#######


require 'webrick'
require "#{$script_dir}/test/browser.rb"

include WEBrick

$unit_test_html= File.read("#{$script_dir}/test/unittest.html")
$script_wrapper_html= File.read("#{$script_dir}/test/scriptwrapper.html")

def replace_tokens(string, params)
	return string.gsub(/(\n[\t ]*)?@([^@ \t\r\n]*)@/) { |m|
		key= $2
		ws= $1
		value= params[key]||m;
		if (ws && ws.length)
			ws + value.split("\n").join(ws);
		else
			value
		end
	}
end

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

def order_files(file, ordered_files= Array.new, probed= Set.new)
  return if probed.include?(file)
  return if ordered_files.include?(file)
  probed << file
  
  file.dependencies.each { |d| order_files(d, ordered_files, probed) }
  ordered_files << file
  
  ordered_files
end
  
#  Create an HTML wrapper file for a JavaScript file. The wrapper will include
#  one script tag for each imported file in the script. This means you don't
#  have to write lots of silly wrapper HTML files for your tests.
def html_wrapper_for_script_file(script_file)
  source_file= SourceFile.from_path(script_file)

  files= order_files(source_file)

  current_dir= File.expand_path('.')

  files.map! { |file|
    # file= file.gsub(/-uncompressed\.js/, '-debug.js')
    file.relative_to_folder(current_dir)
  }
    
  scripts= files.map { |file|
    "<script src=\"#{file}\" type=\"text/javascript\" charset=\"utf-8\"></script>"
  }

  replace_tokens($script_wrapper_html, {
            "scripts" => scripts.join("\n"),
            "title" => "#{script_file}"
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
  declare_option :tests, FileSet
  declare_option :run_tests, false
  
  def initialize(target, options)
    super(target, options)
    @result_queue= Queue.new
    @file_queue= Queue.new

    @files_to_include= @options.tests.to_a
    
    @passed= 0
    @failed= 0
    @skipped= 0
  end

  def self.task_name
    "test"
  end

  def handles_file?(file_name)
    "#{file_name}"[/\.js$/] || "#{file_name}"[/\.html$/]
  end

  def start_webserver()
    access_log_stream = File.open('/dev/null', 'w')
    access_log = [[access_log_stream, AccessLog::COMBINED_LOG_FORMAT]]

    # @server = HTTPServer.new(:Port=>8000)
    #   
    @server = HTTPServer.new(:Port=>8000, :Logger=>Log.new(nil, BasicLog::WARN),
                 :AccessLog=>[])
  
    @server.mount "/wrapped", ScriptWrapper
    @server.mount "/lib", NonCachingFileHandler, $script_dir
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
  
  def cleanup()
    # find the files again, because tests often include output files, which may
    # not be present in a clean build
    find_files

    return if (!@options.run_tests || 'false'===@options.run_tests || 'no'===@options.run_tests)
    return if (0==@included_files.length)
    
    start_webserver
    @server.mount "/unittest", BrowserTestServlet, self

    puts "browsers=#{@options.browsers.inspect}"
    browsers= @options.browsers.map { |b| "#{b}".downcase }
    
    browsers.each { |b|
      browser= ($browsers[b]).new
      next if !browser.supported?

      browser.setup
      browser.visit("http://localhost:8000/unittest")
    
      @included_files.each { |f|

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
