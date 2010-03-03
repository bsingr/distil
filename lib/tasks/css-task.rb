require "#{$script_dir}/tasks/single-output-task.rb"

class CssTask < SingleOutputTask
  
  output_type "css"
  
  # CssTask handles files that end in .css
  def handles_file?(file_name)
    "#{file_name}"[/\.css$/]
  end

end
