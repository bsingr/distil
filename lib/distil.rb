require "set"
require 'yaml'
require 'tempfile'
require 'fileutils'
require 'zlib'
require "open3"

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



require 'distil/error-reporter'
require 'distil/configurable'
require 'distil/interpolated'
require 'distil/project-path'
require 'distil/source-file'
require 'distil/file-set'
require 'distil/task'
require 'distil/target'
require 'distil/project'