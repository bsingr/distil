module Kernel

  def Boolean(string)
    return true if string == true || string =~ /^true$/i
    return false if string == false || string.nil? || string =~ /^false$/i
    raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
  end

end



class Configurable
  attr_reader :options
  
  @@options= {}

  def get_options(settings=nil, parent=nil)
    keys= @@options.keys
    values= @@options.map { |k,v| v[:value] }
  
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
      type= value[:type]
      setting_value= case
        when FalseClass==type || TrueClass==type
          Boolean(setting_value)
        when Array==type
          setting_value.is_a?(String) ? setting_value.split(/\s*,\s*/) : setting_value
        when Fixnum==type
          setting_value.to_i
        when NilClass==type
          setting_value
        when String==type
          setting_value.to_s
        else
          type.new(setting_value)
        end
    
      s[key]= setting_value

    }

    s
  end

  def self.class_attr(name)
    if (@class_attributes.nil?)
      @class_attributes=[name]
    else
      @class_attributes<<name
    end
    
    class_eval %(
          def self.#{name}(*rest)
            if (rest.length>0)
              @#{name}= rest[0]
            else
              @#{name}
            end
          end
          def self.#{name}=(value)
            @#{name}= value
          end
          def #{name}
            @#{name} || self.class.#{name}
          end
          def #{name}=(value)
            @#{name}=value
          end
        )
        
  end
  
  def self.inherited(subclass)
    super(subclass)
    (@class_attributes||[]).each { |a|
        instance_var = "@#{a}"
        subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
      }
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
      info[:value]= nil #arg.new
      arg= rest.shift
    end

    if (!arg.is_a?(Hash))
      info[:value]= arg
      info[:type]= arg.class if !info.key?(:type)
      arg= rest.shift
    end

    # handle named arguments
    if (arg.is_a?(Hash))
      info.merge!(arg)
    end

    @@options[name]= info
  
    Configurable.send :define_method, name do
      @options[name]
    end
  
  end

  def self.option_alias(name, name_alias)
    if (!@@options.key?(name))
      raise ArgumentError, "No such option: #{name}"
    end
  
    name_alias= name_alias.to_s
  
    @@options[name][:aliases].concat([name_alias,
                                      name_alias.to_s.gsub('_', '-'),
                                      name_alias.to_s.gsub('_', ' ')].uniq)
  end
  
  def initialize(options={}, parent=nil)
    if (parent.is_a?(Configurable))
      parent_options= parent.options
    end
    @options= get_options(options, parent_options)
    @extras= options
  end
  
end
