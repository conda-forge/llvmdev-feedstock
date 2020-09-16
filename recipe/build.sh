set -x

# Make osx work like linux.
sed -i.bak "s/NOT APPLE AND ARG_SONAME/ARG_SONAME/g" cmake/modules/AddLLVM.cmake || ${DIRTY}
sed -i.bak "s/NOT APPLE AND NOT ARG_SONAME/NOT ARG_SONAME/g" cmake/modules/AddLLVM.cmake || ${DIRTY}

if [[ ${target_platform} =~ osx.* ]]; then
  cp ${RECIPE_DIR}/xcode-select .
  chmod +x xcode-select
  PATH=${PWD}:${PATH}
fi

[[ -d build ]] || mkdir build
cd build

declare -a CMAKE_ARGS=()

if [[ "$target_platform" == "linux-64" ]]; then
  CMAKE_ARGS+=(-DLLVM_USE_INTEL_JITEVENTS=ON)
fi

if [[ "$CC_FOR_BUILD" != "" && "$CC_FOR_BUILD" != "$CC" ]]; then
  CMAKE_ARGS+=("-DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_C_COMPILER=$CC_FOR_BUILD;-DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD;-DCMAKE_C_FLAGS=-O2;-DCMAKE_CXX_FLAGS=-O2")
fi

if [[ ${target_platform} =~ osx-.* ]]; then
  CMAKE_ARGS+=(-DCMAKE_C_FLAGS=-mlinker-version=305)
  CMAKE_ARGS+=(-DCMAKE_CXX_FLAGS=-mlinker-version=305)
fi

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INCLUDE_TESTS=ON \
      -DLLVM_BUILD_TESTS=ON \
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
      -DLLVM_CCACHE_BUILD=yes \
      "${CMAKE_ARGS[@]}" ..

make -j${CPU_COUNT} ${VERBOSE_CM}

make check-llvm-unit || exit 1


if [[ "${target_platform}" == "linux-64" || "${target_platform}" == "osx-64" ]]; then
    export TEST_CPU_FLAG="-mcpu=haswell"
else
    export TEST_CPU_FLAG=""
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
  bin/opt -S -vector-library=SVML $TEST_CPU_FLAG -O3 $RECIPE_DIR/numba-3016.ll | bin/FileCheck $RECIPE_DIR/numba-3016.ll || exit $?

  #make -j${CPU_COUNT} check-llvm

  cd ../test
  ../build/bin/llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86
fi
