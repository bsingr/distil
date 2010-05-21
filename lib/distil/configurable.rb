module Kernel

  def Boolean(string)
    return true if string == true || string =~ /^true$/i
    return false if string == false || string.nil? || string =~ /^false$/i
    raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
  end

end

class ValidationError < StandardError
end


class Configurable
  attr_reader :options
  
  @@options= {}

  def get_option(name)
    value=@options[name]
    value.respond_to?(:value_of) ? value.value_of(self) : value
  end
  
  def get_options(settings=nil, parent=nil)
    keys= @@options.keys
    values= @@options.map { |k,v| convert_type(v[:type], v[:value]) }
  
    s= Struct.new(*keys).new(*values)
    return s if !settings
  
    setting_keys= settings.keys.map { |key| key.to_s }
  
    @@options.each { |key, value|

      intersect= value[:aliases] & setting_keys
      next if !parent && intersect.empty?

      if (intersect.empty?)
        s[key]= parent[key]
        next
      end
    
      if (intersect.length>1)
        raise ArgumentError, "Multiple variants for #{key.to_s} defined: #{intersect.join(", ")}"
      end
          
      setting_key= intersect[0]
      setting_value= settings[setting_key]
      settings.delete(setting_key)
    
      # decide if any type conversions are needed...
      setting_value= convert_type(value[:type], setting_value)
    
      if (value.has_key?(:valid_values) && !value[:valid_values].include?(setting_value))
        raise ValidationError, "Invalid value for '#{setting_key}': #{setting_value}"
      end
        
      s[key]= setting_value

    }

    s
  end

  # option name, [type], [default], [options]
  def self.option(name, *rest)
  
    name_string= name.to_s
  
    info= {
      :aliases=>[name_string, name_string.gsub('_', '-'), name_string.gsub('_', ' ')].uniq
    }

    arg= rest.shift

    if (arg.is_a?(Class))
      info[:type]= arg
      info[:value]= nil
      arg= rest.shift
    end

    if (!arg.nil? && !arg.is_a?(Hash))
      info[:value]= arg
      info[:type]= arg.class if !info.has_key?(:type)
      arg= rest.shift
    end

    # handle named arguments
    if (arg.is_a?(Hash))
      if arg.has_key?(:aliases)
        info[:aliases].concat(arg[:aliases]).uniq!
        arg.delete(:aliases)
      end
      info.merge!(arg)
    end

    if @@options.has_key?(name)
      orig= @@options[name]
      if orig.has_key?(:type) && info.has_key?(:type) && info[:type]!=orig[:type]
        raise ArgumentError, "Redefinition of option #{self}##{name} changes type"
      end
      if orig.has_key?(:value) && !info[:value].nil? && info[:value]!=orig[:value]
        raise ArgumentError, "Redefinition of option #{name} changes value"
      end
      orig[:type]||=info[:type]
      orig[:value]||=info[:value]
      orig[:aliases].concat(info[:aliases]).uniq!
    else
      @@options[name]= info
    end
    
    self.send :define_method, name do
      value=@options[name]
      value.respond_to?(:value_of) ? value.value_of(self) : value
    end
    
    self.send :define_method, "#{name}=" do |value|
      @options[name]= convert_type(@@options[name][:type], value)
    end
    
    self.send :protected, "#{name}=".to_s
    
  end

  def initialize(options={}, parent=nil)
    if (parent.is_a?(Configurable))
      parent_options= parent.options
    end
    @options= get_options(options, parent_options)
    @extras= options
  end
  
  private
  
  def convert_type(type, value)
    case
    when FalseClass==type || TrueClass==type
      Boolean(value)
    when Array==type
      value.is_a?(String) ? value.split(/\s*,\s*/) : value
    when Fixnum==type
      value.to_i
    when nil==type || NilClass==type
      value
    when String==type
      value ? value.to_s : nil;
    when value.nil?
      value
    else
      if type.respond_to?(:from_options)
        type.from_options(value, self)
      else
        type.new(value)
      end
    end
  end
  
end
