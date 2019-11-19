if [%OCAML_VERSION%]==[] set OCAML_VERSION="4.09.0"

set OPAMROOT=C:/OPAM

set OPAM_URL="https://ci.appveyor.com/api/buildjobs/0ycghl7nkxky59ep/artifacts/opam-msvc64.zip"

echo Downloading opam binary "%OPAM_URL%"
appveyor DownloadFile "%OPAM_URL%" -FileName "%temp%/opam.zip"
mkdir C:/OPAM
7z e "%temp%/opam.zip" -oC:/cygwin/bin
del %temp%/opam.zip

set Path=C:/cygwin/bin;C:/OPAM/bin;%Path%

call "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.cmd" /x64

REM Cygwin is always installed on AppVeyor.  Its path must come
REM before the one of Git but after those of MSCV and OCaml.
set Path=%OCAMLROOT%/bin;%OCAMLROOT%/bin/flexdll;%Path%

set CYGWINBASH=C:/cygwin/bin/bash.exe

if exist %CYGWINBASH% (
  REM Make sure that "link" is the MSVC one and not the Cynwin one.
  echo VCPATH="`cygpath -u -p '%Path%'`" > C:\cygwin\tmp\msenv
  echo PATH="$VCPATH:$PATH" >> C:\cygwin\tmp\msenv
  %CYGWINBASH% -lc "tr -d '\\r' </tmp/msenv > ~/.msenv64"
  %CYGWINBASH% -lc "echo '. ~/.msenv64' >> ~/.bash_profile"
  REM Make OCAMLROOT available in Unix form:
  echo OCAMLROOT_WIN="`cygpath -w -s '%OCAMLROOT%'`" > C:\cygwin\tmp\env
  (echo OCAMLROOT="`cygpath -u \"$OCAMLROOT_WIN\"`") >>C:\cygwin\tmp\env
  echo export OCAMLROOT_WIN OCAMLROOT >>C:\cygwin\tmp\env
  %CYGWINBASH% -lc "tr -d '\\r' </tmp/env >> ~/.bash_profile"
)

opam init --yes --compiler=%OCAML_VERSION% https://github.com/madroach/opam-repository.git
REM stdlib-shims 0.1 is broken on Windows
opam pin --no-action stdlib-shims.0.2.0 "https://github.com/ocaml/stdlib-shims.git#0.2.0"

appveyor SetVariable -Name Path -Value "%Path%"
appveyor SetVariable -Name OPAMROOT -Value "%OPAMROOT%"
set OPAM_SWITCH_PREFIX=%OPAMROOT%/ocaml-system
appveyor SetVariable -Name OPAM_SWITCH_PREFIX -Value "%OPAM_SWITCH_PREFIX%"
set OCAMLLIB=%OCAMLROOT%/lib/ocaml
appveyor SetVariable -Name CAML_LD_LIBRARY_PATH -Value "%CAML_LD_LIBRARY_PATH%"
set CAML_LD_LIBRARY_PATH=%OCAMLROOT%/lib/stublibs:%OPAM_SWITCH_PREFIX%/lib/stublibs
appveyor SetVariable -Name CAML_LD_LIBRARY_PATH -Value "%CAML_LD_LIBRARY_PATH%"
set OCAMLTOP_INCLUDE_PATH="%OPAM_SWITCH_PREFIX%/lib/toplevel"
appveyor SetVariable -Name OCAMLTOP_INCLUDE_PATH -Value "%OCAMLTOP_INCLUDE_PATH%"
set OCAMLPATH="%OPAM_SWITCH_PREFIX%/lib
appveyor SetVariable -Name OCAMLPATH -Value "%OCAMLPATH%"
set OCAMLRUNPARAM="bs=8M"
appveyor SetVariable -Name OCAMLRUNPARAM -Value "%OCAMLRUNPARAM%"

set <NUL /p=Ready to use OCaml & ocamlc -version
