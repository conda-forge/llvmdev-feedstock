echo on

mkdir build
cd build

REM remove GL flag for now
set "CXXFLAGS=-MD"
set "CC=cl.exe"
set "CXX=cl.exe"

cmake -G "Ninja" ^
    -DCMAKE_BUILD_TYPE="Release" ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL ^
    -DLLVM_USE_INTEL_JITEVENTS=ON ^
    -DLLVM_ENABLE_DUMP=ON ^
    -DLLVM_ENABLE_LIBXML2=FORCE_ON ^
    -DLLVM_ENABLE_RTTI=ON ^
    -DLLVM_ENABLE_ZLIB=FORCE_ON ^
    -DLLVM_ENABLE_ZSTD=FORCE_ON ^
    -DLLVM_INCLUDE_BENCHMARKS=OFF ^
    -DLLVM_INCLUDE_DOCS=OFF ^
    -DLLVM_INCLUDE_EXAMPLES=OFF ^
    -DLLVM_INCLUDE_TESTS=ON ^
    -DLLVM_INCLUDE_UTILS=ON ^
    -DLLVM_INSTALL_UTILS=ON ^
    -DLLVM_USE_SYMLINKS=OFF ^
    -DLLVM_UTILS_INSTALL_DIR=libexec\llvm ^
    -DLLVM_BUILD_LLVM_C_DYLIB=ON ^
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly ^
    -DCMAKE_POLICY_DEFAULT_CMP0111=NEW ^
    %SRC_DIR%/llvm
if %ERRORLEVEL% neq 0 exit 1

cmake --build .
if %ERRORLEVEL% neq 0 exit 1

REM bin\opt -S -vector-library=SVML -mcpu=haswell -O3 %RECIPE_DIR%\numba-3016.ll | bin\FileCheck %RECIPE_DIR%\numba-3016.ll
REM if %ERRORLEVEL% neq 0 exit 1

pushd ..\llvm\test
python ..\..\build\bin\llvm-lit.py -vv Transforms ExecutionEngine Analysis CodeGen/X86
popd

:: install everything (will be sliced & diced in meta.yaml)
cmake --install . --prefix=%LIBRARY_PREFIX%
if %ERRORLEVEL% neq 0 exit 1

:: upstream picks up diaguids.lib from the windows image, see
:: https://github.com/llvm/llvm-project/blob/llvmorg-14.0.6/llvm/lib/DebugInfo/PDB/CMakeLists.txt#L17
:: which ultimately derives from VSINSTALLDIR, see
:: https://github.com/llvm/llvm-project/blob/llvmorg-14.0.6/llvm/cmake/config-ix.cmake#L516
:: and gets hardcoded by CMake to point to the path in our windows image.
:: This makes it non-portable between image versions (e.g. 2019 vs 2022), so replace
:: the hardcoded path with a variable again
sed -i "s,C:/Program Files/Microsoft Visual Studio/2022/Enterprise,$ENV{VSINSTALLDIR},g" %LIBRARY_LIB%\cmake\llvm\LLVMExports.cmake
