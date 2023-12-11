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
    -DLLVM_ENABLE_LIBXML2=FORCE_ON ^
    -DLLVM_ENABLE_RTTI=ON ^
    -DLLVM_ENABLE_ZLIB=FORCE_ON ^
    -DLLVM_ENABLE_ZSTD=FORCE_ON ^
    -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON ^
    -DLLVM_INCLUDE_BENCHMARKS=OFF ^
    -DLLVM_INCLUDE_DOCS=OFF ^
    -DLLVM_INCLUDE_EXAMPLES=OFF ^
    -DLLVM_INCLUDE_TESTS=ON ^
    -DLLVM_INCLUDE_UTILS=ON ^
    -DLLVM_INSTALL_UTILS=ON ^
    -DLLVM_USE_SYMLINKS=OFF ^
    -DLLVM_UTILS_INSTALL_DIR=libexec\llvm ^
    -DLLVM_BUILD_LLVM_C_DYLIB=OFF ^
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly ^
    -DCMAKE_POLICY_DEFAULT_CMP0111=NEW ^
    %SRC_DIR%/llvm
if %ERRORLEVEL% neq 0 exit 1

cmake --build .
if %ERRORLEVEL% neq 0 exit 1

REM These tests fail because msdia140.dll isn't registered.
REM The build stalls if registering is attempted in this file, probably because it needs elevated privileges.
REM See https://llvm.org/docs/GettingStartedVS.html#getting-started
set "LIT_FILTER_OUT=DebugInfo/PDB/DIA/pdbdump-flags.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|DebugInfo/PDB/DIA/pdbdump-linenumbers.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|DebugInfo/PDB/DIA/pdbdump-symbol-format.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/checksum-string.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/class-layout.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/complex-padding-graphical.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/enum-layout.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/injected-sources.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/load-address.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/pretty-func-dumper.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/regex-filter.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/simple-padding-graphical.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/symbol-filters.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/type-qualifiers.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-pdbutil/usingnamespace.test"
set "LIT_FILTER_OUT=%LIT_FILTER_OUT%|tools/llvm-symbolizer/pdb/pdb.test"

cmake --build . --target check-llvm

cd ..\llvm\test
%BUILD_PREFIX%\python.exe ..\..\build\bin\llvm-lit.py -vv Transforms ExecutionEngine Analysis CodeGen/X86
