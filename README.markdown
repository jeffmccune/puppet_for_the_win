# For the Win #

This project is a small set of Rake tasks to automate the process of building
MSI packages for Puppet on Windows systems.

# Screen Shots #

The following screen shots show the current state of the graphical installer.
These screen shots are generated automatically.

![Screen 0](http://dl.dropbox.com/u/17169007/img/screenshot_1329206748_0.png)
![Screen 1](http://dl.dropbox.com/u/17169007/img/screenshot_1329206748_1.png)
![Screen 2](http://dl.dropbox.com/u/17169007/img/screenshot_1329206748_2.png)
![Screen 3](http://dl.dropbox.com/u/17169007/img/screenshot_1329206748_3.png)
![Screen 4](http://dl.dropbox.com/u/17169007/img/screenshot_1329206748_4.png)

# Overview #

This is a separate repository because it is meant to build MSI packages for
arbitrary versions of Puppet, Facter and other related tools.

This project is meant to be checked out into a special Puppet Windows Dev Kit
directory structure.  This Dev Kit will provide the tooling necessary to
actually build the packages.

This project requires these tools from the `puppetbuilder` Dev Kit for Windows
systems.

 * Ruby
 * Rake
 * Git
 * 7zip
 * WiX

# Desktop Integration #

Puppet and Facter can be run directly from the Explorer desktop by double
clicking on `run_puppet_interactive.bat` and `run_facter_interactive.bat`.
Shortcuts in the Start Menu will be added for these batch files.

These batch files are not meant to be run from other scripts or the Task
Scheduler because they explicitly pause at the end to give the user a chance to
review the output without `cmd.exe` vanishing on them.  This looks like:

![Run Facter Interactive](http://links.puppetlabs.com/ftw_msi_facter_interactive_1a.png)

# Getting Started #

Given a basic Windows 2003 R2 x64 system with the [Puppet Win
Builder](http://links.puppetlabs.com/puppetwinbuilder) archive unpacked into
`C:/puppetwinbuilder/` the following are all that is required to build the MSI
packages.

    C:\>cd puppetwinbuilder
    C:\puppetwinbuilder\> build
    ...

(REVISIT - This is the thing we're working to.  Make sure this is accurate once
implemented)

# Making Changes #

The [Puppet Win Builder](http://links.puppetlabs.com/puppetwinbuilder) archive
should remain relatively static.  The purpose of this archive is simply to
bootstrap the tools required for the build process.

Changes to the build process itself should happen in the [Puppet For the
Win](https://github.com/puppetlabs/puppet_for_the_win) repository on Github.

# Continuous Integration #

The `build.bat` build script _should_ work just fine with a build system like
Jenkins.  If it does not, please let us know.

# Building from Specific Repositories and Branches #

The build system can be used to build a specific branch or repository of Puppet
and Facter.  To customize the Git reference to build you can first specific the
repositories to clone with the `windows:clone` task and then specify the
reference to checkout using the `windows:checkout` task.

This example builds a package given the latest development heads of the 2.7.x
and 1.6.x integration branches.

    rake clean
    rake windows:clone[git://github.com/puppetlabs/puppet.git,git://github.com/puppetlabs/facter.git]
    rake windows:checkout[origin/2.7.x,origin/1.6.x]
    rake windows:build

# User Facing Customizations #

## Installation Directory CLI ##

The command line installation UX is implemented using the public `INSTALLDIR`
property.

The installation directory may be specified on the command line by passing the
property.  This example logs verbosely to the `install.txt` file and performs a
silent installation to `C:\test\puppet` which is not the default.

    msiexec /qn /l*v install.txt /i puppet.msi INSTALLDIR="C:\test\puppet"

# Public Properties #

All of these are optional and their default values are in parentheses.

 * `INSTALLDIR` (`"%PROGRAMFILES%\Puppet Labs\Puppet"`)
 * `PUPPET_AGENT_CERTNAME` (`[ComputerName]`)
 * `PUPPET_MASTER_HOSTNAME` ("puppet")

EOF
