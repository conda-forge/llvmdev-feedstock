#!/bin/bash
set -x

cd build
ninja install

IFS='.' read -ra VER_ARR <<< "$PKG_VERSION"

# default SOVER for tagged releases is just the major version
SOVER_EXT=${VER_ARR[0]}
if [[ "${PKG_VERSION}" == *dev0 ]]; then
    # otherwise with git suffix
    SOVER_EXT="${SOVER_EXT}git"
fi

if [[ "${PKG_NAME}" == libllvm* ]]; then
    rm -rf $PREFIX/bin
    rm -rf $PREFIX/include
    rm -rf $PREFIX/share
    rm -rf $PREFIX/libexec
    mv $PREFIX/lib $PREFIX/lib2
    mkdir -p $PREFIX/lib
    mv $PREFIX/lib2/libLLVM-${SOVER_EXT}${SHLIB_EXT} $PREFIX/lib
    mv $PREFIX/lib2/lib*.so.${SOVER_EXT} $PREFIX/lib || true
    mv $PREFIX/lib2/lib*.${SOVER_EXT}.dylib $PREFIX/lib || true
    rm -rf $PREFIX/lib2
elif [[ "${PKG_NAME}" == "llvm-tools" ]]; then
    rm -rf $PREFIX/lib
    rm -rf $PREFIX/include
    rm $PREFIX/bin/llvm-config
    rm -rf $PREFIX/libexec
fi

