# For the Win #

This project is a small set of Rake tasks to automate the process of building
MSI packages for Puppet on Windows systems.

# Screen Shots #

The following screen shots show the current state of the graphical installer.
These screen shots are generated automatically.

![Screen 0](http://dl.dropbox.com/u/17169007/img/screenshot_1330473784_1.png)
![Screen 1](http://dl.dropbox.com/u/17169007/img/screenshot_1330385269_1.png)
![Screen 2](http://dl.dropbox.com/u/17169007/img/screenshot_1330385269_2.png)
![Screen 3](http://dl.dropbox.com/u/17169007/img/screenshot_1330385269_3.png)
![Screen 4](http://dl.dropbox.com/u/17169007/img/screenshot_1330385269_4.png)

## Shortcut Icons ##

The current icon being used looks like this:

![Icons](http://dl.dropbox.com/u/17169007/img/screenshoot_1331337674_0_icons.png)

## UAC Integration ##

When running Puppet and Facter interactively using the Start Menu shortcuts,
the process will automatically request Administrator rights using UAC:

![UAC Prompt](http://dl.dropbox.com/u/17169007/img/screenshot_1330369084_0_UAC.png)

## Command Prompt ##

A shortcut named "Start Command Prompt with Puppet" will be created in the
Start Menu.  This shortcut automates the process of starting `cmd.exe` and
manually setting the `PATH` and `RUBYLIB` environment variables.

This command windows looks like this:

![Start Command Prompt with Puppet](http://dl.dropbox.com/u/17169007/img/screenshot_1330411423_shell.png)

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
    rake "windows:clone[git://github.com/puppetlabs/puppet.git,git://github.com/puppetlabs/facter.git]"
    rake "windows:checkout[refs/remotes/origin/2.7.x,refs/remotes/origin/1.6.x]"
    rake windows:build

# User Facing Customizations #

## Installation Directory CLI ##

The command line installation UX is implemented using the public `INSTALLDIR`
property.

The installation directory may be specified on the command line by passing the
property.  This example logs verbosely to the `install.txt` file and performs a
silent installation to `C:\test\puppet` which is not the default.

    msiexec /qn /l*v install.txt /i puppet.msi INSTALLDIR="C:\puppet" PUPPET_MASTER_SERVER="puppetmaster.lan"

# Public Properties #

All of these are optional and their default values are in parentheses.

 * `INSTALLDIR` (`"%PROGRAMFILES%\Puppet Labs\Puppet"`)
 * `PUPPET_AGENT_CERTNAME` (Unset, Puppet will default to using `facter fqdn`)
 * `PUPPET_MASTER_SERVER` ("puppet")
 * `PUPPET_CA_SERVER` (Unset, Puppet will default to using
   `PUPPET_MASTER_SERVER`)

If the `PUPPET_AGENT_CERTNAME` property is not set on the command line when
installing the package, then no `certname` setting will be written to
`puppet.conf`.  There is no ability provided to configure the certificate name
using the graphical installer, `puppet.conf` must be configured
post-installation.  Please see [Ticket
12640](http://projects.puppetlabs.com/issues/12640) for information about why.

The value of `PUPPET_AGENT_CERTNAME` must be lower case as per [Ticket
1168](http://projects.puppetlabs.com/issues/1168)

# Add Remove Programs #

The installer is integrated well with the Add or Remove Programs feature of
Microsoft Windows.  The following screen shots show the current look:

![Add Remove Programs 1](http://dl.dropbox.com/u/17169007/img/screenshot_1329854437_5.png)
![Add Remove Programs 2](http://dl.dropbox.com/u/17169007/img/screenshot_1329854437_6.png)
![Add Remove Programs 3](http://dl.dropbox.com/u/17169007/img/screenshot_1329854437_7.png)

# Puppet Enterprise Facts #

Facts required to connect a Windows Puppet agent to a Puppet Enterprise master
are automatically written to Puppet's confdir.  The facts will be stored in
`%COMMON_APPDATA%/PuppetLabs/facter/facts.d/puppet_installer.txt`

These facts are written for both the Puppet FOSS and Puppet Enterprise branded
installation package.  The following entries are written by default by the
installer and may be changed after the package has been installed.

    fact_stomp_port=61613
    fact_is_puppetagent=true
    fact_is_puppetmaster=false
    fact_is_puppetconsole=false

The stomp server fact defaults to the puppet master hostname specified in the
graphical installer, or using the `PUPPET_MASTER_SERVER` property in the
command line installer.

    fact_stomp_server=puppet

The stomp server and stomp port facts are put in place for future support of
MCollective on Windows.  These facts will not be used until MCollective support
has been added to the Windows packages.

# Remembered Properties #

The Puppet and Puppet Enterprise installers will write the values of user
specified public properties into the following registry paths:

    HKLM\Software\Puppet Labs\PuppetInstaller
      RememberedInstallDir          = INSTALLDIR
      RememberedPuppetMasterServer  = PUPPET_MASTER_SERVER
      RememberedPuppetAgentCertname = PUPPET_AGENT_CERTNAME
      RememberedPuppetCaServer      = PUPPET_CA_SERVER

When the Puppet Enterprise MSI is in an upgrade scenario and is replacing
Puppet FOSS these properties will be "recalled" and filled in as the default
settings in the GUI.  If you are running `puppetenterprise.msi` and you notice
it's automatically filled in the value you previously used for Puppet, this is
how it's getting that information.

# Puppet Configuration Settings #

The MSI package will configure the `archive_files` and `archive_file_server`
settings for Puppet Enterprise.  These configuration settings enable `puppet
inspect` to save files centrally on the Puppet Master to enable the diff view
in the Puppet Enterprise Console.  These two settings are not set when
installing the Puppet FOSS package to match the behavior of Puppet FOSS on
other platforms.

The Puppet Enterprise MSI package also configures `graph=true` to help
visualize the configuration catalog.  This is not set for Puppet FOSS to be
consistent with other platforms.

    C:\ProgramData\PuppetLabs\puppet\etc>more puppet.conf
    [main]
    server=puppetmaster.vm
    pluginsync=true
    autoflush=true
    archive_files=true
    archive_file_server=puppetmaster.vm
    graph=true

# Troubleshooting #

## Missing .NET Framework ##

If you receive exit code 128 when running rake build tasks and it looks like
`candle` and `light` don't actually do anything, it's likely because the
Microsoft .NET Framework is not installed.

If you try to run `candle.exe` or `light.exe` from Explorer, you might receive
"Application Error" - The application failed to initialize properly
(0xC0000135). Click on OK to terminate the application.  This is the same
symptom and .NET should be installed.

In order to resolve this, please use Windows Update to install the .NET
Framework 3.5 (Service Pack 1).

EOF
