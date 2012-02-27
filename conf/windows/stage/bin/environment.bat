@ECHO OFF
REM This is the parent directory of the directory containing this script.
SET PL_BASEDIR=%~dp0..
REM Avoid the nasty \..\ littering the paths.
SET PL_BASEDIR=%PL_BASEDIR:\bin\..=%

REM Get the file name we were originally called as.  e.g. puppet.bat or puppet
REM or facter.bat or facter.  ~n means: will return the file name only of
SET SCRIPT_TEMP=%~n1
REM Strip off the extension of the script name.  We need to do this to know
REM what to pass to ruby -S
SET SCRIPT_NAME=%SCRIPT_TEMP:.bat=%
REM Shift off the original command name we we were called
SHIFT

SET PUPPET_DIR=%PL_BASEDIR%\puppet
SET FACTER_DIR=%PL_BASEDIR%\facter

SET PATH=%PUPPET_DIR%\bin;%FACTER_DIR%\bin;%PL_BASEDIR%\bin;%PL_BASEDIR%\sys\ruby\bin;%PL_BASEDIR%\sys\tools\bin;%PATH%

REM Set the RUBY LOAD_PATH using the RUBYLIB environment variable
SET RUBYLIB=%PUPPET_DIR%\lib;%FACTER_DIR%\lib;%RUBYLIB%

REM Translate all slashes to / style to avoid issue #11930
SET RUBYLIB=%RUBYLIB:\=/%

REM Now return to the caller.
