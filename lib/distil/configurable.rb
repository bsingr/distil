module Distil
  
  class Configurable
  
    @@config_aliases={}
    def self.alias_config_key(original, key_alias)
      @@config_aliases[key_alias.to_s]= original.to_s
    end
    
    def key_for_alias(key_alias)
      key_alias= key_alias.to_s.gsub("-", "_").gsub(" ", "_")
      @@config_aliases[key_alias] || key_alias
    end
    
    class ConfigDsl

      def initialize(hash)
        @hash= hash
        @used= Set.new
      end

      def with_each(key)
        case when @hash.include?(key.to_sym)
          value= @hash[key.to_sym]
        when @hash.include?(key.to_s)
          value= @hash[key.to_s]
        else
          return
        end
        
        value= value.split(",").map { |s| s.strip } if value.is_a?(String)
        value.each { |v| yield v }
        @used << key.to_s
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
      
      def used?(key)
        @used.include?(key.to_s)
      end
      
    end
    
    def configure_with(hash)
      new_hash= {}
      hash.each { |key, value|
        new_hash[key_for_alias(key)]= value
      }
      
      dsl= ConfigDsl.new(new_hash)
      yield dsl if block_given?
      
      new_hash.each { |key, value|
        next if dsl.used?(key.to_s)
        
        key= key_for_alias(key)
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