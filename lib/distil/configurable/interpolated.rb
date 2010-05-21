module Distil
  
  class Interpolated
    
    def initialize(value, owner=nil)
      @value=value
      @owner=owner
    end

    def self.from_options(set, owner)
      self.new(set, owner)
    end
    
    def self.value_of(value, owner)
      return value if !owner
      
      value.gsub(/\$\((\w+)\)/) { |match|
        v= case
        when owner.is_a?(Configurable)
          owner.get_option($1)
        when owner.respond_to?($1)
          owner.send $1
        end
        
        v || "$(#{$1})"
      }
    end
    
    def value_of(owner=nil)
      owner||=@owner
      self.class.value_of(@value, owner)
    end
    
  end
  
end