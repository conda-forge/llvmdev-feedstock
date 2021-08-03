set -x

# Make osx work like linux.
sed -i.bak "s/NOT APPLE AND ARG_SONAME/ARG_SONAME/g" cmake/modules/AddLLVM.cmake
sed -i.bak "s/NOT APPLE AND NOT ARG_SONAME/NOT ARG_SONAME/g" cmake/modules/AddLLVM.cmake

mkdir -p build
cd build

if [[ "$target_platform" == "linux-64" ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_USE_INTEL_JITEVENTS=ON"
  CMAKE_ARGS="${CMAKE_ARGS} -DFFI_INCLUDE_DIR=$PREFIX/include"
  CMAKE_ARGS="${CMAKE_ARGS} -DFFI_LIBRARY_DIR=$PREFIX/lib"
fi

if [[ $target_platform == osx-* ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DFFI_INCLUDE_DIR=${CONDA_BUILD_SYSROOT}/usr/include/ffi"
  CMAKE_ARGS="${CMAKE_ARGS} -DFFI_LIBRARY_DIR=${CONDA_BUILD_SYSROOT}/usr/lib"
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_BUILD_LLVM_C_DYLIB=ON"
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_ENABLE_LIBCXX=ON"
  CMAKE_ARGS="${CMAKE_ARGS} -DRUNTIMES_CMAKE_ARGS=-DCMAKE_INSTALL_RPATH=«loader_path/../lib"
  CMAKE_ARGS="${CMAKE_ARGS} -DDEFAULT_SYSROOT=${CONDA_BUILD_SYSROOT}"

fi

if [[ "$CC_FOR_BUILD" != "" && "$CC_FOR_BUILD" != "$CC" ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_C_COMPILER=$CC_FOR_BUILD;-DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD;-DCMAKE_C_FLAGS=-O2;-DCMAKE_CXX_FLAGS=-O2;-DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,${BUILD_PREFIX}/lib;-DCMAKE_MODULE_LINKER_FLAGS=;-DCMAKE_SHARED_LINKER_FLAGS=;-DCMAKE_STATIC_LINKER_FLAGS=;"
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_HOST_TRIPLE=$(echo $HOST | sed s/conda/unknown/g) -DLLVM_DEFAULT_TARGET_TRIPLE=$(echo $HOST | sed s/conda/unknown/g)"
fi

if [[ ${target_platform} =~ osx-.* ]]; then
    CMAKE_ARGS+=(-DCMAKE_C_FLAGS=-mlinker-version=305)
    CMAKE_ARGS+=(-DCMAKE_CXX_FLAGS=-mlinker-version=305)
    LDFLAGS="${LDFLAGS} -mlinker-version=305"
fi

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INCLUDE_TESTS=ON \
      -DLLVM_INCLUDE_GO_TESTS=OFF \
      -DLLVM_INCLUDE_UTILS=ON \
      -DLLVM_INSTALL_UTILS=ON \
      -DLLVM_UTILS_INSTALL_DIR=libexec/llvm \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_ENABLE_LIBXML2=OFF \
      -DLLVM_ENABLE_ZLIB=ON \
      -DHAVE_LIBEDIT=OFF \
      -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly \
      -DLLVM_BUILD_LLVM_DYLIB=ON \
      -DLLVM_LINK_LLVM_DYLIB=ON \
      -DLLVM_ENABLE_FFI=ON \
      -DLLVM_ENABLE_Z3_SOLVER=OFF \
      -DLLVM_OPTIMIZED_TABLEGEN=ON \
      ${CMAKE_ARGS} ..

make -j${CPU_COUNT}

if [[ "${target_platform}" == "linux-64" || "${target_platform}" == "osx-64" ]]; then
    export TEST_CPU_FLAG="-mcpu=haswell"
else
    export TEST_CPU_FLAG=""
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
  # bin/opt -S -vector-library=SVML $TEST_CPU_FLAG -O3 $RECIPE_DIR/numba-3016.ll | bin/FileCheck $RECIPE_DIR/numba-3016.ll || exit $?

  if [[ "$target_platform" == linux* ]]; then
    ln -s $(which $CC) $BUILD_PREFIX/bin/gcc
  fi

  make -j${CPU_COUNT} check-llvm || true

  cd ../test
  ../build/bin/llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86 || true
fi
