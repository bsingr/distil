module Distil
  
  def self.start_server(project, options)
    require 'webrick'
    require 'directory_watcher'
    
    port= options['server_port'] || 8888;
    path= options['url']
    config= {
      :Port => port
    }

    server= WEBrick::HTTPServer.new(config)
    server.mount(path || '/', WEBrick::HTTPServlet::FileHandler, project.output_folder)

    ['INT', 'TERM'].each { |signal|
       trap(signal){ server.shutdown }
    }

    puts "watching #{project.folder}"
    dw = DirectoryWatcher.new(project.folder, {
      :glob=>"**/*",
      :pre_load => true,
      :interval => 1
    })
    dw.add_observer { |*args|
      args.each { |event|
        puts event
        if :modified==event.type
          puts event.path
        end
      }
    }

    dw.start
    gets
    # b= Browser.new
    # b.open("http://localhost:#{port}/#{path}")
    # server.start
    dw.stop
  end
  
end
