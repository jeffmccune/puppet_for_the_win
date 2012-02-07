#! /usr/bin/env ruby

# This rakefile is meant to be run from within the [Puppet Win
# Builder](http://links.puppetlabs.com/puppetwinbuilder) tree.

# Load Rake
begin
  require 'rake'
rescue LoadError
  retry if require 'rubygems'
  raise
end

require 'rake/clean'

# Add extensions to core Ruby classes
require 'rake/core_extensions'

# Added download task from buildr
require 'rake/downloadtask'
require 'rake/extracttask'
require 'rake/checkpoint'
require 'rake/env'

task :default do
    sh %{rake -T}
end

# Ensure '.' is in the LOAD_PATH in Ruby 1.9.2
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

Dir['tasks/**/*.rake'].each { |t| load t }
