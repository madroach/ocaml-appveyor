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
echo "Clone OCaml branch ${OCAMLBRANCH}${OCAML_PATCHLEVEL:+.}${OCAML_PATCHLEVEL}"
git config --global core.autocrlf false
git clone https://github.com/ocaml/ocaml.git --depth 1 \
    --branch $OCAMLBRANCH${OCAML_PATCHLEVEL:+.}${OCAML_PATCHLEVEL} \
    ocaml

cd ocaml

#PREFIX=$(echo "$OCAMLROOT" | sed -e "s|\\\\|/|g")
PREFIX=$(cygpath -m -s "$OCAMLROOT")

OCAMLBRANCH_MAJOR=`echo "$OCAMLBRANCH" | sed -s 's/\([0-9]\+\).*/\1/'`
OCAMLBRANCH_MINOR=`echo "$OCAMLBRANCH" | sed -s 's/[0-9]\+\.\([0-9]\+\).*/\1/'`
if [[ "$OCAMLBRANCH" != "trunk" \
	  && (($OCAMLBRANCH_MAJOR -eq 4 && $OCAMLBRANCH_MINOR -lt 3) \
		  || $OCAMLBRANCH_MAJOR -lt 4) ]]; then
    run "Apply patch to OCaml sources (quote paths)" \
	patch -p1 < $APPVEYOR_BUILD_FOLDER/ocaml.patch
fi

if [[ ($OCAMLBRANCH_MAJOR -eq 4 && $OCAMLBRANCH_MINOR -lt 8)
      || $OCAMLBRANCH_MAJOR -lt 4 ]]; then

    if [[ "$OCAMLBRANCH" != "trunk" \
	      && (($OCAMLBRANCH_MAJOR -eq 4 && $OCAMLBRANCH_MINOR -lt 5) \
		      || $OCAMLBRANCH_MAJOR -lt 4) ]]; then
	cp config/m-nt.h config/m.h
	cp config/s-nt.h config/s.h
    else
	cp config/m-nt.h byterun/caml/m.h
	cp config/s-nt.h byterun/caml/s.h
    fi

    echo "Edit config/Makefile.msvc64 to set PREFIX=$PREFIX"
    sed -e "/PREFIX=/s|=.*|=$PREFIX|" \
	-e "/^ *CFLAGS *=/s/\r\?$/ -WX\0/" \
	config/Makefile.msvc64 > config/Makefile
    run "Content of config/Makefile" cat config/Makefile

    run "make world" make -f Makefile.nt world
    run "make bootstrap" make -f Makefile.nt bootstrap
    run "make opt" make -f Makefile.nt opt
    run "make opt.opt" make -f Makefile.nt opt.opt
    run "make install" make -f Makefile.nt install
else
    run "Configure" ./configure --build=x86_64-unknown-cygwin --host=x86_64-pc-windows --prefix="$PREFIX"
    run "make world.opt" make world.opt
    run "make install" make install
fi

run "OCaml config" ocamlc -config

#run "env" env
set Path=%OCAMLROOT%\bin;%OCAMLROOT%\bin\flexdll;%Path%
export CAML_LD_LIBRARY_PATH=$PREFIX/lib/stublibs

cd $APPVEYOR_BUILD_FOLDER

if [ -n "$INSTALL_DUNE" ]; then
    cd $APPVEYOR_BUILD_FOLDER
    echo
    echo "-=-=- Install Dune -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    #git clone https://github.com/ocaml/dune.git --depth 1 --branch=master
    git clone https://github.com/Chris00/dune.git --depth 1 --branch=master
    cd dune
    ocaml bootstrap.ml
    run "boot.exe" ./boot.exe --release --display progress
    ./_boot/default/bin/main.exe install dune \
				 --build-dir _boot --prefix "$PREFIX"
    run "dune version" dune --version
    echo "-=-=- Dune installed -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
fi

if [ -n "$INSTALL_OPAM" ]; then
    cd $APPVEYOR_BUILD_FOLDER
    echo
    echo "-=-=- Install OPAM -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    git clone https://github.com/ocaml/opam.git --depth 1
    cd opam
    chmod +x shell/msvs-detect
    run "Configure OPAM with --prefix=$PREFIX" \
        ./configure --prefix="$PREFIX"
    run "Build external libraries" make lib-ext
    run "Build OPAM" make
    run "Install OPAM" make install
    run "opam version" opam --version
fi
