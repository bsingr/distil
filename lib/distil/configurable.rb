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
    
    class ConfigDsl
      
      attr_reader :used
      def initialize(hash)
        @hash= hash
        @used= Set.new
      end
      
      def with(key)
        case when @hash.include?(key.to_sym)
          yield @hash[key.to_sym]
        when @hash.include?(key.to_s)
          yield @hash[key.to_s]
        else
          return
        end
        @used << key.to_s
      end
    end
    
    def configure_with(hash)
      dsl= ConfigDsl.new(hash)
      yield dsl if block_given?
      
      hash.each { |key, value|
        next if dsl.used.include?(key.to_s)
        
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