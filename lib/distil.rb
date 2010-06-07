require "set"
require 'yaml'
require 'tempfile'
require 'fileutils'
require 'zlib'
require "open3"
require 'uri'

def class_attr(*rest)
  rest.each { |name|
    class_eval %(
          def self.#{name}(*rest)
            if (rest.length>0)
              @#{name}= rest[0]
            else
              @#{name} || (superclass.respond_to?(name) ? superclass.#{name} : nil)
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
  }
end

def exist?(path, file)
  File.file?(File.join(path, file))
end

module Distil
  
  FRAMEWORK_TYPE = "framework"
  APP_TYPE = "application"
  
  WEAK_LINKAGE = 'weak'
  STRONG_LINKAGE = 'strong'
  LAZY_LINKAGE = 'lazy'
  
  DEBUG_MODE = 'debug'
  RELEASE_MODE = 'release'
  
end

#  Do a simple token substitution. Tokens begin and end with @.
def replace_tokens(string, params)
	return string.gsub(/(\n[\t ]*)?@([^@ \t\r\n]*)@/) { |m|
		key= $2
		ws= $1
		value= params[key]||m;
		if (ws && ws.length)
			ws + value.split("\n").join(ws);
		else
			value
		end
	}
end



require 'distil/error-reporter'
require 'distil/configurable'
require 'distil/source-file'
require 'distil/task'
require 'distil/product'
require 'distil/target'
require 'distil/project'