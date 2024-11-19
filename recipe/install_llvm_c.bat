echo on

:: this is essentially `bld.bat` with -DLLVM_BUILD_LLVM_C_DYLIB=ON,
:: plus the installation part from `install_llvm.bat`

cd %SRC_DIR%\build

:: remove GL flag for now
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
    %SRC_DIR%/llvm
if %ERRORLEVEL% neq 0 exit 1

cmake --build .
if %ERRORLEVEL% neq 0 exit 1

cd ..
mkdir temp_prefix
mkdir %LIBRARY_LIB%\cmake\llvm

cmake --install .\build --prefix=.\temp_prefix
if %ERRORLEVEL% neq 0 exit 1

:: only libLLVM-C & CMake metadata
move .\temp_prefix\bin\LLVM-C.dll %LIBRARY_BIN%
move .\temp_prefix\lib\LLVM-C.lib %LIBRARY_LIB%
move .\temp_prefix\lib\cmake\llvm\LLVM* %LIBRARY_LIB%\cmake\llvm

rmdir /s /q temp_prefix
