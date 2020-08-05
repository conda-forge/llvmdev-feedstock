set -x

# Make osx work like linux.
sed -i.bak "s/NOT APPLE AND ARG_SONAME/ARG_SONAME/g" cmake/modules/AddLLVM.cmake
sed -i.bak "s/NOT APPLE AND NOT ARG_SONAME/NOT ARG_SONAME/g" cmake/modules/AddLLVM.cmake

mkdir build
cd build

[[ $(uname) == Linux ]] && CMAKE_EXTRA_ARGS="${CMAKE_EXTRA_ARGS} -DLLVM_USE_INTEL_JITEVENTS=ON"

if [[ "$build_platform" != "$target_platform" ]]; then
  if [[ "$target_platform" == "linux-ppc64le" ]]; then
    CMAKE_EXTRA_ARGS="${CMAKE_EXTRA_ARGS} -DCMAKE_SYSTEM_PROCESSOR=ppc64le -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT"
  elif [[ "$target_platform" == "linux-aarch64" ]]; then
    CMAKE_EXTRA_ARGS="${CMAKE_EXTRA_ARGS} -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT"
  fi
  if [[ "$CC_FOR_BUILD" != "" ]]; then
    CMAKE_EXTRA_ARGS="${CMAKE_EXTRA_ARGS} -DCROSS_TOOLCHAIN_FLAGS_NATIVE=\"-DCMAKE_C_COMPILER=$CC_FOR_BUILD -DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD\""
  fi
fi

CMAKE_EXTRA_ARGS="$CMAKE_EXTRA_ARGS -DCMAKE_AR=$AR -DCMAKE_RANLIB=$RANLIB -DCMAKE_LINKER=${LD}"

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
      -DLLVM_BUILD_LLVM_DYLIB=yes \
      -DLLVM_LINK_LLVM_DYLIB=yes \
      ${CMAKE_EXTRA_ARGS} ..

make -j${CPU_COUNT}

if [[ "${target_platform}" == "linux-64" || "${target_platform}" == "osx-64" ]]; then
    export TEST_CPU_FLAG="-mcpu=haswell"
else
    export TEST_CPU_FLAG=""
fi

bin/opt -S -vector-library=SVML $TEST_CPU_FLAG -O3 $RECIPE_DIR/numba-3016.ll | bin/FileCheck $RECIPE_DIR/numba-3016.ll || exit $?

#make -j${CPU_COUNT} check-llvm

cd ../test
../build/bin/llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86
