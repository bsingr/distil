module Distil
  
  class Configurable
  
    @@config_aliases={}
    def self.alias_config_key(original, key_alias)
      @@config_aliases[key_alias.to_s]= original.to_s
    end
    
    def alias_for_key(key_alias)
      key_alias= key_alias.to_s.gsub("-", "_").gsub(" ", "_")
      @@config_aliases[key_alias] || key_alias
    end
    
    def from_hash(hash)
      hash.each { |key, value|
        key= alias_for_key(key)
        case
        when self.respond_to?("#{key}=")
          self.send "#{key}=", value
        when self.respond_to?(key) && 0!=self.method(key).arity
          self.send key, value
        else
          self.instance_variable_set("@#{key}", value)
        end
      }
    end
    
  end
  
end