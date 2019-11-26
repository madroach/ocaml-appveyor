#!/bin/bash

function run {
    NAME=$1
    shift
    echo "-=-=- $NAME -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    "$@"
    CODE=$?
    if [ $CODE -ne 0 ]; then
        echo "-=-=- $NAME failed! -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
        exit $CODE
    else
        echo "-=-=- End of $NAME -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    fi
}

cd $APPVEYOR_BUILD_FOLDER

# Do not perform end-of-line conversion
echo "Clone OCaml version ${OCAML_VERSION}"
git config --global core.autocrlf false
git clone https://github.com/ocaml/ocaml.git --depth 1 \
    --branch $OCAML_VERSION \
    ocaml

cd ocaml

#PREFIX=$(echo "$OCAMLROOT" | sed -e "s|\\\\|/|g")
PREFIX=$(cygpath -m -s "$OCAMLROOT")

OCAML_MAJOR=`echo "$OCAML_VERSION" | sed -s 's/\([0-9]\+\).*/\1/'`
OCAML_MINOR=`echo "$OCAML_VERSION" | sed -s 's/[0-9]\+\.\([0-9]\+\).*/\1/'`
OCAML_PATCH=`echo "$OCAML_VERSION" | sed -s 's/[0-9]\+\.[0-9]\+\.\([0-9]\+\).*/\1/'`

run "Configure" ./configure --build=x86_64-unknown-cygwin --host=x86_64-pc-windows --prefix="$PREFIX"
run "make world.opt" make world.opt
run "make install" make install

run "OCaml config" ocamlc -config

#run "env" env
set Path=%OCAMLROOT%\bin;%OCAMLROOT%\bin\flexdll;%Path%
export CAML_LD_LIBRARY_PATH=$PREFIX/lib/stublibs

echo
echo "-=-=- Install Dune -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
cd $APPVEYOR_BUILD_FOLDER
#git clone https://github.com/ocaml/dune.git --depth 1 --branch=master
git clone https://github.com/Chris00/dune.git --depth 1 --branch=master
cd dune
ocaml bootstrap.ml
run "boot.exe" ./boot.exe --release --display progress
./_boot/default/bin/main.exe install dune \
			     --build-dir _boot --prefix "$PREFIX"
run "dune version" dune --version
echo "-=-=- Dune installed -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

echo
echo "-=-=- Install OPAM -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
cd $APPVEYOR_BUILD_FOLDER
git clone https://github.com/ocaml/opam.git --depth 1
cd opam
chmod +x shell/msvs-detect
run "Configure OPAM with --prefix=$PREFIX" ./configure --prefix="$PREFIX"
run "Build external libraries" make lib-ext
run "Build OPAM" make
run "Install OPAM" make install
run "opam version" opam --version

echo "-=-=- set up OPAM -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
cd $APPVEYOR_BUILD_FOLDER
OPAMROOT=C:/OPAM
OPAM_SWITCH_PREFIX="${OPAMROOT}/ocaml-system"
export OCAMLLIB="${OCAMLROOT}/lib/ocaml"
export CAML_LD_LIBRARY_PATH="${OCAMLROOT}/lib/stublibs:${OPAM_SWITCH_PREFIX}/lib/stublibs"
export OCAMLTOP_INCLUDE_PATH="${OPAM_SWITCH_PREFIX}/lib/toplevel"
export OCAMLPATH="${OPAM_SWITCH_PREFIX}/lib"
opam init --yes --compiler=ocaml-system https://github.com/madroach/opam-repository.git
# stdlib-shims 0.1 is broken on Windows
opam pin --no-action stdlib-shims.0.2.0 "https://github.com/ocaml/stdlib-shims.git#0.2.0"
opam install --yes dune ocamlbuild batteries containers seq iter astring cmdliner ounit alcotest
