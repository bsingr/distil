require "set"
require 'yaml'
require 'tempfile'
require 'fileutils'
require 'zlib'
require "open3"
require 'uri'
require 'erb'
require 'open-uri'
require 'json'

module Distil
  class ValidationError < StandardError
  end

  LIB_DIR= File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  VENDOR_DIR= File.expand_path(File.join(File.dirname(__FILE__), "..", "vendor"))
  ASSETS_DIR= File.expand_path(File.join(File.dirname(__FILE__), "..", "assets"))
  APP_NAME= File.basename($0)
  
  COMPRESSOR= File.expand_path("#{VENDOR_DIR}/yuicompressor-2.4.2.jar")
  
end

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

require 'distil/error-reporter'
require 'distil/subclass-tracker'
require 'distil/configurable'
require 'distil/source-file'
require 'distil/file-vendor'
require 'distil/product'
require 'distil/project'
require 'distil/recursive-http-fetcher'
require 'distil/remote-asset'
