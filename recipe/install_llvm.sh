cd build
make install
if [[ "${PKG_NAME}" == "llvmdev" ]]; then
    rm $PREFIX/lib/libLLVM-*${SHLIB_EXT}*
fi
