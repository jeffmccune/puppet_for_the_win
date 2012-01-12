require 'rake'

# This rakefile is meant to be run from within the
# [Puppet Win Builder](http://links.puppetlabs.com/puppetwinbuilder)
# tree.

task :default => :help

desc "List available rake tasks"
task :help do
  sh 'rake -T'
end

# The update task is always called from the build script
# This gives the repository an opportunity to update itself
# and manage how it updates itself.
desc "Update the build scripts"
task :update do
  puts "Update is not implemented yet."
end

# This is also called from the build script in the Puppet Win Builder archive.
# This will be called AFTER the update task in a new process.
desc "Build everything"
task :build do
  puts "Build task is not implemented yet."
end
