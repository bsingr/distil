# require "#{$script_dir}/configurable"

class Filter
  
  @@filters= []
  def self.inherited(subclass)
    @@filters << subclass.new
  end

  def self.abstract
    false
  end
  
  def self.each
    @@filters.each { |f|
      yield f
    }
  end
  
  def self.defined
    @@filters
  end
  
  def handles_file(file)
    false
  end

  def preprocess_content(file, content)
    content
  end
  
  def filter_content(file, content, options={})
    content
  end
  
end

# load all the other file types
Dir.glob("#{$script_dir}/filters/*-filter.rb") { |file|
  require file
}
