set -x
mkdir build
cd build

[[ $(uname) == Linux ]] && conditional_args="
      -DLLVM_USE_INTEL_JITEVENTS=ON
"
cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_GO_TESTS=OFF \
      -DLLVM_INCLUDE_UTILS=ON \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_ENABLE_LIBXML2=OFF \
      -DLLVM_ENABLE_ZLIB=OFF \
      -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly \
      ${conditional_args} ..

make -j${CPU_COUNT}
make install || exit $?
bin/opt -S -vector-library=SVML -mcpu=haswell -O3 $RECIPE_DIR/numba-3016.ll | bin/FileCheck $RECIPE_DIR/numba-3016.ll || exit $?
#cd ../test
#../build/bin/llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86
