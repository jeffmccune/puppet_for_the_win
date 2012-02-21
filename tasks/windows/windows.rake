#! /usr/bin/env ruby

# This rakefile is meant to be run from within the [Puppet Win
# Builder](http://links.puppetlabs.com/puppetwinbuilder) tree.

# Load Rake
begin
  require 'rake'
rescue LoadError
  require 'rubygems'
  require 'rake'
end

require 'rake/clean'

# Added download task from buildr
require 'rake/downloadtask'

# Where we're situated in the filesystem relative to the Rakefile
TOPDIR=File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))

# This method should be called by candle to figure out the list of variables
# we're defining "outside" the build system.  Git describe and what have you.
# This is ultimately set by the environment variable BRANDING which could be
# foss|enterprise
def variable_define_flags
  flags = Hash.new
  flags['PuppetDescTag'] = describe 'downloads/puppet'
  flags['FacterDescTag'] = describe 'downloads/facter'

  # The regular expression with back reference groups for version string
  # parsing.  We re-use this against either git-describe on Puppet or on
  # ENV['PE_VERSION_STRING'] which should match the same pattern.  NOTE that we
  # can only use numbers in the product version and that product version
  # impacts major upgrades: ProductVersion Property is defined as
  # [0-255].[0-255].[0-65535] See:
  # http://stackoverflow.com/questions/9312221/msi-version-numbers
  # This regular expression focuses on the major numbers and discards things like "rc1" in the string
  version_regexps = [
    /(\d+)[^.]*?\.(\d+)[^.]*?\.(\d+)[^.]*?-(\d+)-(.*)/,
    /(\d+)[^.]*?\.(\d+)[^.]*?\.(\d+)[^.]*?\.(\d+)/,
    /(\d+)[^.]*?\.(\d+)[^.]*?\.(\d+)[^.]*?/,
  ]

  case ENV['BRANDING']
  when /enterprise/i
    flags['PackageBrand'] = "enterprise"
    msg = "Could not parse PE_VERSION_STRING env variable.  Set it with something like PE_VERSION_STRING=2.5.0"
    # The Package Version components for FOSS
    match_data = nil
    version_regexps.find(lambda { raise ArgumentError, msg }) do |re|
      match_data = ENV['PE_VERSION_STRING'].match re
    end
    flags['MajorVersion'] = match_data[1]
    flags['MinorVersion'] = match_data[2]
    flags['BuildVersion'] = match_data[3]
    flags['Revision'] = match_data[4] || 0
  else
    flags['PackageBrand'] = "foss"
    msg = "Could not parse git-describe annotated tag for Puppet"
    # The Package Version components for FOSS
    match_data = nil
    version_regexps.find(lambda { raise ArgumentError, msg }) do |re|
      match_data = flags['PuppetDescTag'].match re
    end
    flags['MajorVersion'] = match_data[1]
    flags['MinorVersion'] = match_data[2]
    flags['BuildVersion'] = match_data[3]
    flags['Revision'] = match_data[4] || 0
  end

  # Return the string of flags suitable for candle
  flags.inject([]) { |a, (k,v)| a << "-d#{k}=\"#{v}\"" }.join " "
end

def describe(dir)
  @git_tags ||= Hash.new
  @git_tags[dir] ||= Dir.chdir(dir) { %x{git describe}.chomp }
end

# Produce a wixobj from a wxs file.
def candle(wxs_file, flags=[])
  flags_string = flags.join(' ')
  if ENV['BUILD_UI_ONLY'] then
    flags_string << " -dBUILD_UI_ONLY"
  end
  flags_string << " -dlicenseRtf=conf/windows/stage/misc/LICENSE.rtf"
  flags_string << " " << variable_define_flags
  Dir.chdir File.join(TOPDIR, File.dirname(wxs_file)) do
    sh "candle -ext WixUIExtension -arch x86 #{flags_string} #{File.basename(wxs_file)}"
  end
end

# Produce a wxs file from a directory in the stagedir
# e.g. heat('wxs/fragments/foo.wxs', 'stagedir/sys/foo')
def heat(wxs_file, stage_dir)
  Dir.chdir TOPDIR do
    cg_name = File.basename(wxs_file.ext(''))
    dir_ref = File.basename(File.dirname(stage_dir))
    # NOTE:  The reference specified using the -dr flag MUST exist in the
    # parent puppet.wxs file.  Otherwise, WiX won't be able to graft the
    # fragment into the right place in the package.
    dir_ref = 'INSTALLDIR' if dir_ref == 'stagedir'
    sh "heat dir #{stage_dir} -v -ke -indent 2 -cg #{cg_name} -gg -dr #{dir_ref} -var var.StageDir -out #{wxs_file}"
  end
end

def unzip(zip_file, dir)
  Dir.chdir TOPDIR do
    Dir.chdir dir do
      sh "7za -y x #{File.join(TOPDIR, zip_file)}"
    end
  end
end

def gitclone(target, uri)
  Dir.chdir(File.dirname(target)) do
    sh "git clone #{uri} #{File.basename(target)}"
  end
end

CLOBBER.include('downloads/*')
CLEAN.include('stagedir/*')
CLEAN.include('wix/fragments/*.wxs')
CLEAN.include('wix/**/*.wixobj')
CLEAN.include('pkg/*')

namespace :windows do
  # These are file tasks that behave like mkdir -p
  directory 'pkg'
  directory 'downloads'
  directory 'stagedir/sys'
  directory 'wix/fragments'

  ## File Lists

  TARGETS = FileList['pkg/puppet.msi']

  # These translate to ZIP files we'll download
  # FEATURES = %w{ ruby git wix misc }
  FEATURES = %w{ ruby }
  # These are the applications we're packaging from VCS source
  APPS = %w{ facter puppet }
  # Thse are the pre-compiled things we need to stage and include in
  # the packages
  DOWNLOADS = FEATURES.collect { |fn| File.join("downloads", fn.ext('zip')) }

  # We do this to provide a cache of sorts, allowing rake clean to clean but
  # preventing the build tasks from having to re-clone all of puppet and facter
  # which usually takes ~ 3 minutes.
  GITREPOS  = APPS.collect { |fn| File.join("downloads", fn.ext('')) }

  # These files provide customization of the installer strings.
  LOCALIZED_STRINGS = FileList['wix/**/*.wxl']

  # These are the VCS repositories checked out into downloads.
  # For example, downloads/puppet and downloads/facter
  GITREPOS.each do |repo|
    file repo, [:uri] => ['downloads'] do |t, args|
      args.with_defaults(:uri => "git://github.com/puppetlabs/#{File.basename(t.name).ext('.git')}")
      Dir.chdir File.dirname(t.name) do
        sh "git clone #{args[:uri]} #{File.basename(t.name)}"
      end
    end

    # These tasks are not meant to be executed every build They're meant to
    # provide the means to checkout the reference we want prior to running the
    # build.  See the windows:checkout task for more information
    task "checkout.#{File.basename(repo.ext(''))}", [:ref] => [repo] do |t, args|
      repo_dir = t.name.gsub(/^.*?checkout\./, 'downloads/')
      args.with_defaults(:ref => 'refs/remotes/origin/master')
      Dir.chdir repo_dir do
        sh 'git fetch origin'
        sh 'git fetch origin --tags'
        # We explicitly avoid using git clean -x because we rely on rake clean
        # to clean up build artifacts.  Specifically, we don't want to clone
        # and download zip files every single build
        sh 'git clean -f -d'
        sh "git checkout -f #{args[:ref]}"
      end
    end
  end

  # There is a 1:1 mapping between a wxs file and a wixobj file
  # The wxs files in the top level of wix/ should be committed to VCS
  WXSFILES = FileList['wix/*.wxs']
  # WXS Fragments could have different types of sources and are generated
  # during the build process by heat.exe
  WXS_FRAGMENTS_HASH = {
    'ruby' => { :src => 'stagedir/sys/ruby' },
    'puppet' => { :src => 'stagedir/puppet' },
    'facter' => { :src => 'stagedir/facter' },
  }
  # WXS UI Fragments.  These are static and should not be cleaned, though the
  # objects they compile into should be.  These are different than the objects
  # produced by heat because they only contain UI customizations and no actual
  # files or components or such.
  WXS_UI_FRAGMENTS = FileList['wix/ui/*.wxs']
  WXS_UI_OBJS = WXS_UI_FRAGMENTS.ext('wixobj')

  # Additional directories to stage as fragments automatically.
  # conf/windows/stagedir/bin/ for example.
  FileList[File.join(TOPDIR, 'conf', 'windows', 'stage', '*')].each do |fn|
    my_topdir = File.basename(fn)
    WXS_FRAGMENTS_HASH[my_topdir] = { :src => "stagedir/#{my_topdir}" }
    file "stagedir/#{my_topdir}" => ["stagedir"] do |t|
      src = File.join(TOPDIR, 'conf', 'windows', 'stage', File.basename(t.name))
      dst = t.name
      FileUtils.cp_r src, dst
    end
    task :stage => ["stagedir/#{my_topdir}"]
  end

  # These files should be auto-generated by heat
  WXS_FRAGMENTS = WXS_FRAGMENTS_HASH.keys.collect do |fn|
    File.join("wix", "fragments", fn.ext('wxs'))
  end
  # All of the objects we need to create
  WIXOBJS = (WXSFILES + WXS_FRAGMENTS).ext('wixobj')
  # UI Only objects we need to link.  Filter out the large objects like Ruby, Puppet and Facter
  # These objects need to match up to the preprocessor conditional in puppet.wxs
  WIXOBJS_MIN = (WXSFILES + WXS_FRAGMENTS.find_all { |f| f =~ /misc|bin/ }).ext 'wixobj'
  # These directories should be unpacked into stagedir/sys
  SYSTOOLS = FEATURES.collect { |fn| File.join("stagedir", "sys", fn) }

  task :default => :build
  # High Level Tasks.  Other tasks will add themselves to these tasks
  # dependencies.

  # This is also called from the build script in the Puppet Win Builder archive.
  # This will be called AFTER the update task in a new process.
  desc "Build puppet.msi"
  task :build do |t|
    ENV['BRANDING'] ||= "foss"
    Rake::Task["pkg/puppet.msi"].invoke
  end

  desc "Build puppet_ui_only.msi"
  task :buildui do |t|
    ENV['BRANDING'] ||= "foss"
    ENV['BUILD_UI_ONLY'] ||= 'true'
    Rake::Task["pkg/puppet_ui_only.msi"].invoke
  end

  desc "Build puppetenterprise.msi"
  task :buildenterprise do |t|
    ENV['BRANDING'] ||= "enterprise"
    if not ENV['PE_VERSION_STRING']
      puts "Warning: PE_VERSION_STRING is not set in the environment.  Defaulting to 2.5.0-0-0"
      ENV['PE_VERSION_STRING'] = '2.5.0-0-0'
    end
    Rake::Task["pkg/puppetenterprise.msi"].invoke
  end

  desc "Build puppet_ui_only.msi"
  task :buildenterpriseui do |t|
    ENV['BRANDING'] ||= "enterprise"
    ENV['BUILD_UI_ONLY'] ||= 'true'
    if not ENV['PE_VERSION_STRING']
      puts "Warning: PE_VERSION_STRING is not set in the environment.  Defaulting to 2.5.0-0-0"
      ENV['PE_VERSION_STRING'] = '2.5.0-0-0'
    end
    Rake::Task["pkg/puppetenterprise_ui_only.msi"].invoke
  end

  desc "Download example"
  task :download => DOWNLOADS

  # Note, other tasks may append themselves as necessary for the stage task.
  desc "Stage everything to be built"
  task :stage => SYSTOOLS

  desc "Clone upstream repositories"
  task :clone, [:puppet_uri, :facter_uri] => ['downloads'] do |t, args|
    baseuri = "git://github.com/puppetlabs"
    args.with_defaults(:puppet_uri => "#{baseuri}/puppet.git",
                       :facter_uri => "#{baseuri}/facter.git")
    Rake::Task["downloads/puppet"].invoke(args[:puppet_uri])
    Rake::Task["downloads/facter"].invoke(args[:facter_uri])
  end

  desc "Checkout app repositories to a specific ref"
  task :checkout, [:puppet_ref, :facter_ref] => [:clone] do |t, args|
    # args.with_defaults(:puppet_ref => 'refs/remotes/origin/2.7.x',
    #                    :facter_ref => 'refs/remotes/origin/1.6.x')
    args.with_defaults(:puppet_ref => 'refs/tags/2.7.9',
                       :facter_ref => 'refs/tags/1.6.4')
    # This is an example of how to invoke other tasks that take parameters from
    # a task that takes parameters.
    Rake::Task["windows:checkout.facter"].invoke(args[:facter_ref])
    Rake::Task["windows:checkout.puppet"].invoke(args[:puppet_ref])
  end

  desc "List available rake tasks"
  task :help do
    sh 'rake -T'
  end

  # The update task is always called from the build script
  # This gives the repository an opportunity to update itself
  # and manage how it updates itself.
  desc "Update the build scripts"
  task :update do
    sh 'git pull'
  end

  # Tasks to unpack the zip files
  SYSTOOLS.each do |systool|
    zip_file = File.join("downloads", File.basename(systool).ext('zip'))
    file systool => [ zip_file, File.dirname(systool) ] do
      unzip(zip_file, File.dirname(systool))
    end
  end

  DOWNLOADS.each do |fn|
    file fn => [ File.dirname(fn) ] do |t|
      download t.name => "http://downloads.puppetlabs.com/development/ftw/#{File.basename(t.name)}"
    end
  end

  WIXOBJS.each do |wixobj|
    source_dir = WXS_FRAGMENTS_HASH[File.basename(wixobj.ext(''))][:src]
    file wixobj => [ wixobj.ext('wxs'), File.dirname(wixobj) ] do |t|
      candle(t.name.ext('wxs'), [ "-dStageDir=#{source_dir}" ] )
    end
  end

  WXS_UI_OBJS.each do |wixobj|
    file wixobj => [ wixobj.ext('wxs') ] do |t|
      candle(t.name.ext('wxs'))
    end
  end

  WXS_FRAGMENTS.each do |wxs_frag|
    source_dir = WXS_FRAGMENTS_HASH[File.basename(wxs_frag.ext(''))][:src]
    file wxs_frag => [ source_dir, File.dirname(wxs_frag) ] do |t|
      heat(t.name, source_dir)
    end
  end

  # We stage whatever is checked out using the checkout parameterized task.
  APPS.each do |app|
    file "stagedir/#{app}" => ['stagedir', "downloads/#{app}"] do |t|
      my_app = File.basename(t.name.ext(''))
      puts "Copying downloads/#{my_app} to #{t.name} ..."
      FileUtils.mkdir_p t.name
      # This avoids copying hidden files like .gitignore and .git
      FileUtils.cp_r FileList["downloads/#{my_app}/*"], t.name
    end
    # The stage task needs these directories to be in place.
    task :stage => ["stagedir/#{app}"]
  end

  # REVISIT - DRY THIS SECTION UP, lots of copy paste code here...
  file 'pkg/puppet.msi' => WIXOBJS + WXS_UI_OBJS + LOCALIZED_STRINGS do |t|
    objects_to_link = t.prerequisites.reject { |f| f =~ /wxl$/ }.join(' ')
    sh "light -ext WixUIExtension -cultures:en-us -loc wix/localization/puppet_en-us.wxl -out #{t.name} #{objects_to_link}"
  end

  file 'pkg/puppetenterprise.msi' => WIXOBJS + WXS_UI_OBJS + LOCALIZED_STRINGS do |t|
    objects_to_link = t.prerequisites.reject { |f| f =~ /wxl$/ }.join(' ')
    sh "light -ext WixUIExtension -cultures:en-us -loc wix/localization/puppet_en-us.wxl -out #{t.name} #{objects_to_link}"
  end

  file 'pkg/puppet_ui_only.msi' => WIXOBJS_MIN + WXS_UI_OBJS + LOCALIZED_STRINGS do |t|
    objects_to_link = t.prerequisites.reject { |f| f =~ /wxl$/ }.join(' ')
    sh "light -ext WixUIExtension -cultures:en-us -loc wix/localization/puppet_en-us.wxl -out #{t.name} #{objects_to_link}"
  end

  file 'pkg/puppetenterprise_ui_only.msi' => WIXOBJS_MIN + WXS_UI_OBJS + LOCALIZED_STRINGS do |t|
    objects_to_link = t.prerequisites.reject { |f| f =~ /wxl$/ }.join(' ')
    sh "light -ext WixUIExtension -cultures:en-us -loc wix/localization/puppet_en-us.wxl -out #{t.name} #{objects_to_link}"
  end

  desc 'Install the MSI using msiexec'
  task :install => [ 'pkg/puppet.msi', 'pkg' ] do |t|
    Dir.chdir "pkg" do
      sh 'msiexec /q /l*v install.txt /i puppet.msi INSTALLDIR="C:\puppet" PUPPET_MASTER_HOSTNAME="puppetmaster" PUPPET_AGENT_CERTNAME="windows.vm"'
    end
  end

  desc 'Uninstall the MSI using msiexec'
  task :uninstall => [ 'pkg/puppet.msi', 'pkg' ] do |t|
    Dir.chdir "pkg" do
      sh 'msiexec /qn /l*v uninstall.txt /x puppet.msi'
    end
  end
end
