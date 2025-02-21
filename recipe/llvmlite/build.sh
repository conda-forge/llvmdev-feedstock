#!/bin/bash

set -x

pushd "${SRC_DIR}/llvmlite"

export PYTHONNOUSERSITE=1

export LLVMLITE_USE_CMAKE=1
if [[ "${target_platform}" == "linux-ppc64le" ]]; then
    export LLVMLITE_SHARED=1
else
    export LLVMLITE_SHARED=0
fi

if [[ "${target_platform}" == osx-* ]]; then
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

$PYTHON setup.py build --force
$PYTHON setup.py install

popd
