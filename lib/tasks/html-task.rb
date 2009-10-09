require "#{$script_dir}/tasks/output-task.rb"

class HtmlTask < Task
  
  def self.task_name
    "html"
  end
  
  # CssTask handles files that end in .css
  def handles_file?(file_name)
    "#{file_name}"[/\.html$/]
  end

end
