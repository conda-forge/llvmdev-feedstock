#!/bin/bash
set -ex

IFS='.' read -ra VER_ARR <<< "$PKG_VERSION"

# temporary prefix to be able to install files more granularly
mkdir temp_prefix

if [[ "${PKG_NAME}" == libllvm-c* ]]; then
    cmake --install ./build --prefix=./temp_prefix
    # only libLLVM-C
    mv ./temp_prefix/lib/libLLVM-C${VER_ARR[0]}${SHLIB_EXT} $PREFIX/lib
elif [[ "${PKG_NAME}" == libllvm* ]]; then
    cmake --install ./build --prefix=./temp_prefix
    # all other libraries
    mv ./temp_prefix/lib/libLLVM-${VER_ARR[0]}${SHLIB_EXT} $PREFIX/lib
    mv ./temp_prefix/lib/lib*.so.${VER_ARR[0]} $PREFIX/lib || true
    mv ./temp_prefix/lib/lib*.${VER_ARR[0]}.dylib $PREFIX/lib || true
elif [[ "${PKG_NAME}" == "llvm-tools" ]]; then
    cmake --install ./build --prefix=./temp_prefix
    # everything in /bin & /share
    mv ./temp_prefix/bin/* $PREFIX/bin
    mv ./temp_prefix/share/* $PREFIX/share
    # except one binary that belongs to llvmdev
    rm $PREFIX/bin/llvm-config
else
    # llvmdev: install everything else
    cmake --install ./build --prefix=$PREFIX
fi

rm -rf temp_prefix
