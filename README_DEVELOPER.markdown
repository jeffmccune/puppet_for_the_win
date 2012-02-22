# Setup Tips #

To get a shared filesystem:

    net use Z: "\\vmware-host\Shared Folders" /persistent:yes

# CRLF #

In order to preserve CRLF line endings on batch files we recommend setting
these two configuration values.  More information about the implications of
doing so are available in the `git help config` man page.

    # ~/.gitconfig
    autocrlf = false
    safecrlf = true

# Common Issues #

I seem to be getting this a lot downloading files:

    undefined method `zero?' for nil:NilClass

This appears to be from the call to the progress bar method having nil content
from the response.content\_length here:

    % ack with_progress_bar
    rake/contrib/uri_ext.rb
    161:    #   with_progress_bar(enable, file_name, size) { |progress| ... }
    171:    def with_progress_bar(enable, file_name, size) #:nodoc:
    254:            with_progress_bar options[:progress], path.split('/').last, response.content_length do |progress|

# WiX Properties #

Setting WiX properties conditionally looks like nothing I've ever seen before
so I'll mention it here.  The idiom to set a property for a dialog screen
appears to be to define a CustomAction that executes in a previous screen or
step.

Information specific to working with with Properties and conditionals is
available at [Using Properties in Conditional
Statements](http://msdn.microsoft.com/en-us/library/aa372435.aspx)

The CustomAction can be conditional using the syntax defined at [Conditional
Statement Syntax](http://msdn.microsoft.com/en-us/library/aa368012.aspx)
Here's an example used in the [Remember Property
Pattern](http://robmensching.com/blog/posts/2010/5/2/The-WiX-toolsets-Remember-Property-pattern)

    <Custom Action='SaveCmdLineInstallDir' Before='AppSearch' />
    <Custom Action='SetFromCmdLineInstallDir' After='AppSearch'>
      CMDLINE_INSTALLDIR
    </Custom>

In this example the `SaveCmdLineInstallDir` will act unconditionally while the
`SetFromCmdLineInstallDir` action will act only when the `CMDLINE_INSTALLDIR`
property is set.

This technique can be used to conditionally set properties that aren't
explicitly set by the user.

# Build the UI Only #

To build this special package an environment variable must also be set
like so:

    rake windows:buildui

The resulting package will be in `pkg/puppet_ui_only.msi`

This is MUCH faster than building the full package.

For Puppet Enterprise the following build task will build the UI only.

    rake windows:buildenterpriseui

The resulting package will be in `pkg/puppetenterprise_ui_only.msi`

# Branding #

This build system currently packages the same software components regardless of
the branding.  The build system will produce packages for Puppet Enterprise and
for Puppet.  The major difference between these two different packages are the
graphics used in the graphical installation, the version numbers embedded
into the package, and the reference information and documentation.

The version identifier will be calculated based on the output of `git describe`
against the Puppet repository currently checked out.  The numeric values for
each of the major version components will be used and alphanumeric substrings
will be stripped.

For example, if `git describe` returns `2.7.10-257-g1518894` then the package
version will become `2.7.10.257`.  This corresponds to the following mapping to
windows terminology for version strings.

 * Major Version = 2
 * Minor Version = 7
 * Build = 10
 * Revision = 257

From a support perspective, if I'm looking at a version string inside of
Windows, I know this package was built from a version of Puppet 257 commits
ahead of the 2.7.10 annotated tag in version control.

The welcome screen itself will display the actual output of `git describe`
which can identify the exact head used to build the package.

## Puppet ##

To build the puppet.msi package, simply execute:

    rake windows:build


## Puppet Enterprise ##

To build the puppetenterprise.msi package, simply execute:

    rake windows:buildenterprise PE_VERSION_STRING=2.5.0

Since the build system cannot automatically determine the version of Puppet
Enterprise being packaged the version information needs to be specified as an
environment variable when compiling the package.  This version string will
result in the following windows versions:

 * Major Version = 2
 * Minor Version = 5
 * Build = 0
 * Revision = 0

# Localization Strings #

The strings used throughout the installer are defined in the file
`wix/Localization/puppet_en-us.wxl`.  In the future if we support other
languages than English we will need to create additional localization files.  A
convenient place to get started is the WiX source code in the
`src/ext/UIExtension/wixlib/*.wxl` directory.

For the time being, any customization of strings shown to the user needs to
happen inside of `puppet_en-us.wxl`.

In addition, customization of text styles (color, size, font) needs to have a
new TextStyle defined in `wix/include/textstyles.wxi`

# Screen shots #

You can use the included `ext/screenshots` script to automate the process of
updating the README file with current images.

# Modifying the included Ruby #

The copy of Ruby is created by simply zipping up the `stagedir/sys/ruby`
directory into `ruby.zip`  I recently removed some gems following this process:

    C:\>SET PATH=Z:\vagrant\win\puppetwinbuilder\src\puppet_for_the_win\stagedir\sys\ruby\bin;%PATH%
    gem uninstall rspec
    gem uninstall rspec-core
    gem uninstall mocha
    ...

Then back on my Mac:

    % cd /vagrant/src/puppet_for_the_win/stagedir/sys
    % zip -r ruby.zip ruby
    % scp ruby.zip downloads.puppetlabs.com:/opt/downloads/development/ftw/

This produces a new archive and uploads it to the webserver the rake tasks will
download from if the file doesn't exist locally.  To use the new zip file
delete the previous one from `downloads/ruby.zip` or use the `rake clobber`
task.

# Ruby Debug #

I'm debugging using Cygwin Ruby with rubygems installed via `setup.rb`.  Here's how to install the ruby-debug gem:

    gem install ruby-debug --platform=mswin32

EOF
