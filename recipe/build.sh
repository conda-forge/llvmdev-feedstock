#!/bin/bash

set -exuo pipefail

export CXXFLAGS="${CXXFLAGS} -std=c++17"

if [[ "${target_platform}" == osx-* ]]; then
  export LDFLAGS="${LDFLAGS} -lz -framework CoreFoundation -Xlinker -undefined -Xlinker dynamic_lookup"
else
  export LDFLAGS="${LDFLAGS} -lrt"
fi

pushd utils/bazel
source gen-bazel-toolchain
bazel build --crosstool_top=//bazel_toolchain:toolchain --cpu ${TARGET_CPU}  @llvm-project//llvm/... @llvm-project//mlir/...
popd

mkdir -p ${PREFIX}/share/llvm_for_tf
cp -ap llvm ${PREFIX}/share/llvm_for_tf/
cp -ap mlir ${PREFIX}/share/llvm_for_tf/
rsync -a utils/bazel/llvm-project-overlay/ ${PREFIX}/share/llvm_for_tf/
# These files will be generated by the Python script below, ensure that we
# don't accidentially keep the original.
rm ${PREFIX}/share/llvm_for_tf/llvm/BUILD.bazel
rm ${PREFIX}/share/llvm_for_tf/mlir/BUILD.bazel

# Delete some files that break LIEF (and aren't needed)
rm -rf ${PREFIX}/share/llvm_for_tf/clang/test/
rm -rf ${PREFIX}/share/llvm_for_tf/llvm/test/
rm -rf ${PREFIX}/share/llvm_for_tf/llvm/utils/lit/tests
find ${PREFIX}/share/llvm_for_tf -name '*.a' -delete
find ${PREFIX}/share/llvm_for_tf -name '*.exe' -delete
find ${PREFIX}/share/llvm_for_tf -name '*.dll' -delete
find ${PREFIX}/share/llvm_for_tf -name '*.o' -delete

mkdir -p ${PREFIX}/lib/llvm_for_tf
python $RECIPE_DIR/compile_bundle.py
