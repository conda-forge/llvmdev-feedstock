#!/bin/bash
set -x

IFS='.' read -ra VER_ARR <<< "$PKG_VERSION"

cd build
# Move prefix out of the way so our rm -rfs do not muck up
# post-link checks which require the host prefix to not be
# destroyed (we could perhaps check this? Prefix files are
# recorded before each build, if any are missing we might
# want to  create a new env to do post-link checks in, and
# really this needs a warning emitted too.
# WARNING: Files have been deleted from the prefix. Post-link
# WARNING: checks will be slower as a temporary env must be
# WARNING: created to check DSOs (when conda-build implemnts
# that feature).

make check-llvm-unit
mkdir -p $(dirname /tmp$PREFIX)
make install DESTDIR=/tmp
pushd $PREFIX
find . > ${SRC_DIR}/${PKG_NAME}-filelist.0-prefix.txt
popd
pushd /tmp$PREFIX
find . > ${SRC_DIR}/${PKG_NAME}-filelist.1-tmp-prefix.txt
if [[ ${PKG_NAME} =~ libllvm.* ]]; then
    rm -rf bin include share libexec
    mv lib lib2
    mkdir lib
    mv lib2/libLLVM-${VER_ARR[0]}${SHLIB_EXT} lib
    # For .so files
    mv lib2/lib*${SHLIB_EXT}.${VER_ARR[0]} lib || true
    # For .dylib files
    mv lib2/lib*.${VER_ARR[0]}${SHLIB_EXT} lib || true
    rm -rf lib2
elif [[ "${PKG_NAME}" == "llvm-tools" ]]; then
    rm -rf lib include bin/llvm-config libexec
fi
popd
pushd /tmp$PREFIX/
cp -rf * $PREFIX/
pushd $PREFIX
    find . > ${SRC_DIR}/${PKG_NAME}-filelist.2-prefix.txt
popd
popd
