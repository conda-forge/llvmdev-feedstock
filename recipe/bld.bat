echo on
setlocal enabledelayedexpansion

mkdir build
cd build

set

REM remove GL flag for now
set "CXXFLAGS=-MD"
set "CC=cl.exe"
set "CXX=cl.exe"

if NOT "%target_platform%"=="%build_platform%" (
    echo "LIB: %LIB%"
    echo "LIB_FOR_BUILD: %LIB_FOR_BUILD%"
    echo set^(CMAKE_C_COMPILER "%CC_FOR_BUILD:\=/%"^)       >> cross-toolchain.cmake
    echo set^(CMAKE_CXX_COMPILER "%CXX_FOR_BUILD:\=/%"^)   >> cross-toolchain.cmake
    echo set^(CMAKE_C_FLAGS ""^)                            >> cross-toolchain.cmake
    echo set^(CMAKE_CXX_FLAGS ""^)                          >> cross-toolchain.cmake
    echo set^(CMAKE_EXE_LINKER_FLAGS "/MACHINE:X64"^)       >> cross-toolchain.cmake
    echo set^(CMAKE_MODULE_LINKER_FLAGS ""^)                >> cross-toolchain.cmake
    echo set^(CMAKE_SHARED_LINKER_FLAGS ""^)                >> cross-toolchain.cmake
    echo set^(CMAKE_STATIC_LINKER_FLAGS ""^)                >> cross-toolchain.cmake
    echo set^(LLVM_INCLUDE_BENCHMARKS "OFF"^)               >> cross-toolchain.cmake
    echo set^(LLVM_ENABLE_ZSTD "OFF"^)                      >> cross-toolchain.cmake
    echo set^(LLVM_ENABLE_LIBXML2 "OFF"^)                   >> cross-toolchain.cmake
    echo set^(LLVM_ENABLE_ZLIB "OFF"^)                      >> cross-toolchain.cmake
    echo set^(CMAKE_LIBRARY_PATH "%LIB_FOR_BUILD:\=/%"^)        >> cross-toolchain.cmake
    echo set^(CMAKE_INCLUDE_PATH "%INCLUDE_FOR_BUILD:\=/%"^)    >> cross-toolchain.cmake
    echo set^(ENV{INCLUDE} "%INCLUDE_FOR_BUILD:\=/%"^)      >> cross-toolchain.cmake
    echo set^(ENV{LIB} "%LIB_FOR_BUILD:\=/%"^)              >> cross-toolchain.cmake
    type cross-toolchain.cmake
    set "CMAKE_ARGS=%CMAKE_ARGS% -DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_TOOLCHAIN_FILE=%cd%\\cross-toolchain.cmake"
)

:: debug
echo CMAKE_ARGS=!CMAKE_ARGS!

cmake !CMAKE_ARGS! -G "Ninja" ^
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

:: :: takes ~30min
:: cd ..\llvm\test
:: python ..\..\build\bin\llvm-lit.py -vv Transforms ExecutionEngine Analysis CodeGen/X86
:: if %ERRORLEVEL% neq 0 exit 1
