mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
<<<<<<< Updated upstream
      -DCMAKE_PREFIX_PATH="${PREFIX}" \
=======
      -DCMAKE_INSTALL_LIBDIR=lib \
>>>>>>> Stashed changes
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_TARGETS_TO_BUILD=host \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_UTILS=OFF \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_ENABLE_TERMINFO=OFF \
      ..

make -j${CPU_COUNT}
make install
