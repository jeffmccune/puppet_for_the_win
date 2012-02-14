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

    rake windows:buildui BUILD_UI_ONLY=true

The resulting package will be in `pkg/puppet_ui_only.msi`

This is MUCH faster than building the full package.

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

EOF
