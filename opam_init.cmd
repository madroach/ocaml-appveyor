if [%OCAML_BRANCH%]==[] set OCAML_BRANCH="4.09"

set ProgramFiles=C:/PROGRA~1
set "OCAMLROOT=%ProgramFiles%/OCaml"
set OPAMROOT=C:/OPAM

set BUILD_ID=mj6ayadmp3hn2rdu
set "URL=https://ci.appveyor.com/api/projects/madroach/ocaml-appveyor/artifacts/"

echo Downloading binaries from %URL% version %OCAML_BRANCH%
appveyor DownloadFile "%URL%/ocaml-%OCAML_BRANCH%.zip" -FileName "%temp%/ocaml.zip"
mkdir "%OCAMLROOT%"
cd "%OCAMLROOT%"
7z x "%temp%/ocaml.zip"
dir "%OCAMLROOT%"
del "%temp%/ocaml.zip"

if not [%OPAM%]==[] (
  appveyor DownloadFile "%URL%/opam-%OCAML_BRANCH%.zip" -FileName "%temp%/opam.zip"
  mkdir "%OPAMROOT%"
  cd "%OPAMROOT%"
  7z x "%temp%/opam.zip"
  dir "%OPAMROOT%"
  del "%temp%/opam.zip"
)

cd "%APPVEYOR_BUILD_FOLDER%"

REM Cygwin is always installed on AppVeyor.  Its path must come
REM before the one of Git but after those of MSCV and OCaml.
set "Path=%OCAMLROOT%/bin;%OCAMLROOT%/bin/flexdll;C:/cygwin/bin;%Path%"

call "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.cmd" /x64

appveyor SetVariable -Name Path -Value "%Path%"
appveyor SetVariable -Name OPAMROOT -Value "%OPAMROOT%"
set "OPAM_SWITCH_PREFIX=%OPAMROOT%/ocaml-system"
appveyor SetVariable -Name OPAM_SWITCH_PREFIX -Value "%OPAM_SWITCH_PREFIX%"
set "OCAMLLIB=%OCAMLROOT%/lib/ocaml"
appveyor SetVariable -Name CAML_LD_LIBRARY_PATH -Value "%CAML_LD_LIBRARY_PATH%"
set "CAML_LD_LIBRARY_PATH=%OCAMLROOT%/lib/stublibs:%OPAM_SWITCH_PREFIX%/lib/stublibs"
appveyor SetVariable -Name CAML_LD_LIBRARY_PATH -Value "%CAML_LD_LIBRARY_PATH%"
set "OCAMLTOP_INCLUDE_PATH=%OPAM_SWITCH_PREFIX%/lib/toplevel"
appveyor SetVariable -Name OCAMLTOP_INCLUDE_PATH -Value "%OCAMLTOP_INCLUDE_PATH%"
set "OCAMLPATH="%OPAM_SWITCH_PREFIX%/lib"
appveyor SetVariable -Name OCAMLPATH -Value "%OCAMLPATH%"
set "OCAMLRUNPARAM=bs=8M"
appveyor SetVariable -Name OCAMLRUNPARAM -Value "%OCAMLRUNPARAM%"

set <NUL /p=Ready to use OCaml & ocamlc -version
