require "#{$script_dir}/tasks/output-task.rb"

class HtmlTask < Task
  
  def self.task_name
    "html"
  end
  
  def initialize(target, options)
    super(target, options)
    @files_to_exclude= @options.exclude.to_a
    @files_to_include= @options.include.to_a
  end    

  # CssTask handles files that end in .css
  def handles_file?(file_name)
    "#{file_name}"[/\.html$/]
  end

end
