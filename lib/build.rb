#!/usr/bin/env ruby

$script_dir= File.expand_path(File.dirname(__FILE__))
$vendor_dir= File.expand_path(File.join($script_dir, "..", "vendor"))

require 'yaml'
require "#{$script_dir}/target"

arg_settings= {}
files= Array.new

ARGV.each { |v|
    if (!v[/^-/])
        files << v
        next
    end
    
    v= v.gsub(/^-+/, '')
    v.gsub!("-", "_")
    
    key,value= v.split("=")
    if (!value)
        value= true
    end
    arg_settings[key.to_sym]= value
}

Task.set_global_options({
        :name=> File.basename(files[0], File.extname(files[0])),
        :formats=> ["concat", "gz", "min", "debug"],
        :output_folder=> Dir.getwd
    })

Task.set_global_options(arg_settings)

build_info= YAML.load_file(files[0])
Task.set_global_options(build_info)

options= Task.options
if (options.targets)
    if (options.targets.is_a?(String))
        options.targets= options.targets.split(/\s*,\s*/)
    end
end

build_info.each { |section, value|
    next if (options.targets && !options.targets.include?(section))
    next if ((!options.targets || !options.targets.include?(section)) &&
             value.is_a?(Hash) && value.has_key?("enabled") && !value["enabled"])

    puts
    puts "#{section}:"
    puts
        
    target= Target.new(section, value)
    Target.current= target
    target.process_all_files
    target.finish
}
