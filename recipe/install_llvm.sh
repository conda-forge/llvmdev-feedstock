#!/bin/bash
set -x

cd build
ninja install

IFS='.' read -ra VER_ARR <<< "$PKG_VERSION"

if [[ "${PKG_NAME}" == libllvm* ]]; then
    rm -rf $PREFIX/bin
    rm -rf $PREFIX/include
    rm -rf $PREFIX/share
    rm -rf $PREFIX/libexec
    mv $PREFIX/lib $PREFIX/lib2
    mkdir -p $PREFIX/lib
    if [ -f $PREFIX/lib2/libLLVM-${VER_ARR[0]}git${SHLIB_EXT} ]; then
        mv $PREFIX/lib2/libLLVM-${VER_ARR[0]}git${SHLIB_EXT} $PREFIX/lib
    else
        mv $PREFIX/lib2/libLLVM-${VER_ARR[0]}${SHLIB_EXT} $PREFIX/lib
    fi
    mv $PREFIX/lib2/lib*.so.${VER_ARR[0]} $PREFIX/lib || true
    mv $PREFIX/lib2/lib*.${VER_ARR[0]}.dylib $PREFIX/lib || true
    rm -rf $PREFIX/lib2
elif [[ "${PKG_NAME}" == "llvm-tools" ]]; then
    rm -rf $PREFIX/lib
    rm -rf $PREFIX/include
    rm $PREFIX/bin/llvm-config
    rm -rf $PREFIX/libexec
fi

