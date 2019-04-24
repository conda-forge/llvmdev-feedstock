make install
if [[ "${PKG_NAME}" == "llvmdev" ]]; then
    rm $PREFIX/libLLVM-*${SHLIB_EXT}*
fi
