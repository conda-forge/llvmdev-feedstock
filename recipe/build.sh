#!/bin/bash
set -exo pipefail

# Make osx work like linux.
sed -i.bak "s/NOT APPLE AND ARG_SONAME/ARG_SONAME/g" llvm/cmake/modules/AddLLVM.cmake
sed -i.bak "s/NOT APPLE AND NOT ARG_SONAME/NOT ARG_SONAME/g" llvm/cmake/modules/AddLLVM.cmake

mkdir build
cd build

if [[ "$target_platform" == "linux-64" ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_USE_INTEL_JITEVENTS=ON"
fi

if [[ "$CC_FOR_BUILD" != "" && "$CC_FOR_BUILD" != "$CC" ]]; then
  NATIVE_FLAGS="-DCMAKE_C_COMPILER=$CC_FOR_BUILD;-DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD;-DCMAKE_C_FLAGS=-O2;-DCMAKE_CXX_FLAGS=-O2"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,${BUILD_PREFIX}/lib;-DCMAKE_MODULE_LINKER_FLAGS=;-DCMAKE_SHARED_LINKER_FLAGS="
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_STATIC_LINKER_FLAGS=;-DLLVM_INCLUDE_BENCHMARKS=OFF"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DLLVM_ENABLE_ZSTD=OFF;-DLLVM_ENABLE_LIBXML2=OFF;-DLLVM_ENABLE_ZLIB=OFF;"
  CMAKE_ARGS="${CMAKE_ARGS} -DCROSS_TOOLCHAIN_FLAGS_NATIVE=${NATIVE_FLAGS}"
fi

# disable -fno-plt due to https://bugs.llvm.org/show_bug.cgi?id=51863 due to some GCC bug
if [[ "$target_platform" == "linux-ppc64le" ]]; then
  CFLAGS="$(echo $CFLAGS | sed 's/-fno-plt //g')"
  CXXFLAGS="$(echo $CXXFLAGS | sed 's/-fno-plt //g')"
  CMAKE_ARGS="${CMAKE_ARGS} -DFFI_INCLUDE_DIR=$PREFIX/include"
  CMAKE_ARGS="${CMAKE_ARGS} -DFFI_LIBRARY_DIR=$PREFIX/lib"
fi

if [[ $target_platform == osx-* ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DFFI_INCLUDE_DIR=${CONDA_BUILD_SYSROOT}/usr/include/ffi"
  CMAKE_ARGS="${CMAKE_ARGS} -DFFI_LIBRARY_DIR=${CONDA_BUILD_SYSROOT}/usr/lib"
  # https://github.com/llvm/llvm-project/issues/64657
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_BUILD_LLVM_C_DYLIB=OFF"
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_ENABLE_LIBCXX=ON"
  CMAKE_ARGS="${CMAKE_ARGS} -DRUNTIMES_CMAKE_ARGS=-DCMAKE_INSTALL_RPATH=«loader_path/../lib"
  CMAKE_ARGS="${CMAKE_ARGS} -DDEFAULT_SYSROOT=${CONDA_BUILD_SYSROOT}"
fi

if [[ $target_platform == osx-arm64 ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_ENABLE_WERROR=FALSE"
fi

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_LIBRARY_PATH="${PREFIX}" \
      -DLLVM_ENABLE_LIBEDIT=OFF \
      -DLLVM_ENABLE_LIBXML2=FORCE_ON \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_ENABLE_ZLIB=FORCE_ON \
      -DLLVM_ENABLE_ZSTD=FORCE_ON \
      -DLLVM_INCLUDE_BENCHMARKS=OFF \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_ENABLE_FFI=ON \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_INCLUDE_GO_TESTS=OFF \
      -DLLVM_INCLUDE_TESTS=ON \
      -DLLVM_INCLUDE_UTILS=ON \
      -DLLVM_INSTALL_UTILS=ON \
      -DLLVM_BUILD_LLVM_DYLIB=ON \
      -DLLVM_LINK_LLVM_DYLIB=ON \
      -DLLVM_UTILS_INSTALL_DIR=libexec/llvm \
      -DHAVE_CXX_ATOMICS_WITHOUT_LIB=TRUE \
      -DHAVE_CXX_ATOMICS64_WITHOUT_LIB=TRUE \
      ${CMAKE_ARGS} \
      -GNinja \
      ../llvm

      # -DLLVM_BUILD_LLVM_C_DYNLIB=ON \
      # -DLLVM_OPTIMIZED_TABLEGEN=ON \
      # -DCMAKE_POLICY_DEFAULT_CMP0111=NEW \


ninja -j${CPU_COUNT}

if [[ "${target_platform}" == "linux-64" || "${target_platform}" == "osx-64" ]]; then
    export TEST_CPU_FLAG="-mcpu=haswell"
else
    export TEST_CPU_FLAG=""
fi

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} != "1" ]]; then
  # bin/opt -S -vector-library=SVML $TEST_CPU_FLAG -O3 $RECIPE_DIR/numba-3016.ll | bin/FileCheck $RECIPE_DIR/numba-3016.ll || exit $?

  if [[ "$target_platform" == linux* ]]; then
    ln -s $(which $CC) $BUILD_PREFIX/bin/gcc

    # These tests tests permission-based behaviour and probably fail because of some
    # filesystem-related reason. They are sporadic failures and don't seem serious so they're excluded.
    # Note that indents would introduce spaces into the environment variable
    export LIT_FILTER_OUT='tools/llvm-ar/error-opening-permission.test|'\
'tools/llvm-dwarfdump/X86/output.s|'\
'tools/llvm-ifs/fail-file-write.test|'\
'tools/llvm-ranlib/error-opening-permission.test'

  elif [[ "$target_platform" == osx* ]]; then
    export LIT_FILTER_OUT='tools/llvm-objcopy/ELF/strip-preserve-atime.test'
  fi

  # check-llvm takes >1.5h to build & run on osx
  ninja -j${CPU_COUNT} check-llvm

  cd ../llvm/test
  ${PYTHON} ../../build/bin/llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86
fi