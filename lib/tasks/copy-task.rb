class CopyTask < Task
  
  def initialize(target, options)
    super(target, options)
    @files_to_exclude= @options.exclude.to_a
    @files_to_include= @options.include.to_a
  end    

  def need_to_build
    true
  end
  
  def handles_file?(file_name)
    true
  end

end
