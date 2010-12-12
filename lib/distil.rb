require "rubygems"
require "set"
require 'yaml'
require 'tempfile'
require 'fileutils'
require 'zlib'
require "open3"
require 'uri'
require 'erb'
require 'open-uri'
require "json"

module Distil
  class ValidationError < StandardError
  end

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

class String
  def as_identifier
    word= self.to_s.gsub(/(?:^|\W)(.)/) { $1.upcase }
    word[0..0].downcase + word[1..-1]
  end
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end
end

require 'distil/hash-additions'
require 'distil/javascript-code'
require 'distil/error-reporter'
require 'distil/subclass-tracker'
require 'distil/configurable'
require 'distil/source-file'
require 'distil/file-vendor'
require 'distil/product'
require 'distil/javascript-file-validator'
require 'distil/project'
require 'distil/recursive-http-fetcher'
require 'distil/library'
require 'distil/browser'
require 'distil/server'
