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
git config --global core.autocrlf false
git clone https://github.com/ocaml/ocaml.git --branch $OCAMLBRANCH \
    --depth 1 ocaml

cd ocaml

OCAMLBRANCH_MAJOR=`echo "$OCAMLBRANCH" | sed -s 's/\([0-9]\+\).*/\1/'`
OCAMLBRANCH_MINOR=`echo "$OCAMLBRANCH" | sed -s 's/[0-9]\+\.\([0-9]\+\).*/\1/'`
if [[ ($OCAMLBRANCH_MAJOR -eq 4 && $OCAMLBRANCH_MINOR -lt 3) \
	  || $OCAMLBRANCH_MAJOR -lt 4 ]]; then
    run "Apply patch to OCaml sources (quote paths)" \
	patch -p1 < $APPVEYOR_BUILD_FOLDER/ocaml.patch
fi

cp config/m-nt.h config/m.h
cp config/s-nt.h config/s.h
#cp config/Makefile.msvc config/Makefile
cp config/Makefile.msvc64 config/Makefile

#PREFIX=$(echo "$OCAMLROOT" | sed -e "s|\\\\|/|g")
PREFIX=$(cygpath -m -s "$OCAMLROOT")
echo "Edit config/Makefile so set PREFIX=$PREFIX"
cp config/Makefile config/Makefile.bak
sed -e "s|PREFIX=.*|PREFIX=$PREFIX|" config/Makefile.bak > config/Makefile
run "Content of config/Makefile" cat config/Makefile

run "make world" make -f Makefile.nt world
run "make bootstrap" make -f Makefile.nt bootstrap
run "make opt" make -f Makefile.nt opt
run "make opt.opt" make -f Makefile.nt opt.opt
run "make install" make -f Makefile.nt install

#run "env" env
export CAML_LD_LIBRARY_PATH=$PREFIX/lib/stublibs

cd $APPVEYOR_BUILD_FOLDER

if [ -n "$BUILDOPAM" ]; then
    echo "Build OPAM"
    git clone https://github.com/ocaml/opam.git --depth 1
    cd opam
    OPAM_INSTALL="C:/opam"
    run "Configure OPAM with --prefix=$OPAM_INSTALL" \
        env DJDIR=workaround ./configure --prefix="$OPAM_INSTALL"

    # The dose 3 tarball contains a symlink which cases problems with tar:
    patch -p1 < $APPVEYOR_BUILD_FOLDER/opam.patch
    appveyor DownloadFile "https://github.com/Chris00/ocaml-appveyor/releases/download/0.1/dose.3.3.opam.tar.gz" -FileName "src_ext/dose.3.3+opam.tar.gz"

    run "Build external libraries" make lib-ext
    run "Build OPAM" make
    #run "Install OPAM" make install
    # ls "$OPAM_INSTALL"
    # mv "$OPAM_INSTALL"/* "$PREFIX/"
    # Install by hand, the above installation procedure fails on Cygwin/Mingw
    cp src/opam "$PREFIX/bin/opam.exe"
    cp src/opam-admin "$PREFIX/bin/opam-admin.exe"
    cp src/opam-admin.top "$PREFIX/bin/opam-admin-top.exe"
    cp src/opam-installer "$PREFIX/bin/opam-installer.exe"
fi

if [ -n "$OCAMLFIND_VERSION" ]; then
    cd $APPVEYOR_BUILD_FOLDER

    echo "Build ocamlfind..."
    appveyor DownloadFile "http://download.camlcity.org/download/findlib-${OCAMLFIND_VERSION}.tar.gz"
    tar xvf findlib-${OCAMLFIND_VERSION}.tar.gz
    cd findlib-${OCAMLFIND_VERSION}
    ROOT=$(cygpath -m "$PREFIX")
    ROOT=$(cygpath -u "$ROOT")
    # Man path not protected against spaces:
    BINDIR="$ROOT/bin"
    SITELIB="$ROOT/lib/site-lib"
    MANDIR="$ROOT/man"
    CONFIG="$ROOT/etc/findlib.conf"
    echo "bindir =$BINDIR"
    echo "sitelib=$SITELIB"
    echo "mandir =$MANDIR"
    ./configure -bindir "$BINDIR" -sitelib "$SITELIB" -mandir "$MANDIR" \
                -config "$CONFIG"
    run "Makefile.config" cat Makefile.config
    run "Build ocamlfind (byte)" make all
    run "Build ocamlfind (native)" make opt
    run "Install ocamlfind" make install
    # Small test:
    run "Content of $CONFIG" cat "$CONFIG"
    run "ocamlfind printconf" ocamlfind printconf || true
fi
