require 'distil/configurable/interpolated'

module Distil
  
  class ProjectPath < Interpolated
    
    def self.value_of(value, owner)
      return value if !owner
      
      value= super(value, owner)

      return value if 0==value.index(File::SEPARATOR)
      return value if !owner.is_a?(Configurable)
      
      path= owner.get_option("path")
      return value if !path || path.empty?
      
      return value if value!=path && 0==value.index(path)
      
      File.join(path, value)
    end
    
  end
  
end
