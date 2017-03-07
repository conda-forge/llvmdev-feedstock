mkdir build
cd build

# Not supported until trunk/4.xx: -DLLVM_CCACHE_BUILD=$ENABLE_CCACHE \
# Instead work with explicit CC=ccache cc
#if [ -x "$(command -v ccache)" ]; then
#  ENABLE_CCACHE=ON
#else
#  ENABLE_CCACHE=OFF
#  echo "WARNING: Failed to find ccache"
#fi

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_UTILS=OFF \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_ENABLE_TERMINFO=OFF \
      ..

echo "Building -j${CPU_COUNT}"
make -j${CPU_COUNT}
make install
