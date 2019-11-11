set OCAMLROOT=C:/PROGRA~1/OCaml
set OPAMROOT=C:/OPAM

if not defined OCAML_BRANCH (set OCAML_BRANCH=4.09)
set OCAMLURL="https://ci.appveyor.com/api/projects/madroach/ocaml-appveyor/artifacts/ocaml-%OCAML_BRANCH%.zip"

echo Downloading OCaml %OCAML_BRANCH% from "%OCAMLURL%"
appveyor DownloadFile "%OCAMLURL%" -FileName "%temp%/ocaml.zip"
cd "%PROGRAMFILES%"
7z x -y "%temp%/ocaml.zip"
del %temp%/ocaml.zip

set Path=C:/cygwin/bin;%Path%

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

opam init --yes --compiler=ocaml-system https://github.com/madroach/opam-repository.git
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
