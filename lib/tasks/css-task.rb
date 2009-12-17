require "#{$script_dir}/tasks/single-output-task.rb"

class CssTask < SingleOutputTask
  
  def self.task_name
    "css"
  end
  
  def output_type
    "css"
  end
  
  # CssTask handles files that end in .css
  def handles_file?(file_name)
    "#{file_name}"[/\.css$/]
  end

end
