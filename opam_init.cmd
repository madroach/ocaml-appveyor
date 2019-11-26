if [%OCAML_VERSION%]==[] set OCAML_VERSION="4.09.0"

set OCAMLROOT=%ProgramFiles%/OCaml
set OPAMROOT=C:/OPAM

set OPAM_URL="https://ci.appveyor.com/api/buildjobs/3uscc6wmf1thv0vx/artifacts/ocaml-4.09.0.zip"

echo Downloading opam binary %OPAM_URL%
appveyor DownloadFile "%OPAM_URL%" -FileName "%temp%/ocaml.zip"
cd %ProgramFiles%
7z x "%temp%/ocaml.zip"
dir "%OCAMLROOT%"
del "%temp%/ocaml.zip"

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
