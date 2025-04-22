@echo on

:: temporary prefix to be able to install files more granularly
mkdir temp_prefix


if "%PKG_NAME%" == "libllvm-c%PKG_VERSION:~0,2%" (
    cmake --install .\build --prefix=.\temp_prefix
    if %ERRORLEVEL% neq 0 exit 1
    REM only libLLVM-C
    move .\temp_prefix\bin\LLVM-C.dll %LIBRARY_BIN%
    move .\temp_prefix\lib\LLVM-C.lib %LIBRARY_LIB%
) else if "%PKG_NAME%" == "llvm-tools" (
    cmake --install ./build --prefix=./temp_prefix
    if %ERRORLEVEL% neq 0 exit 1

    mkdir %LIBRARY_PREFIX%\share
    REM all the executables (not .dll's) in \bin & everything in \share
    move .\temp_prefix\bin\*.exe %LIBRARY_BIN%
    move .\temp_prefix\share\* %LIBRARY_PREFIX%\share
) else (
    REM llvmdev: everything else
    cmake --install .\build --prefix=%LIBRARY_PREFIX%
    if %ERRORLEVEL% neq 0 exit 1

    REM upstream picks up diaguids.lib from the windows image, see
    REM https://github.com/llvm/llvm-project/blob/llvmorg-14.0.6/llvm/lib/DebugInfo/PDB/CMakeLists.txt#L17
    REM which ultimately derives from VSINSTALLDIR, see
    REM https://github.com/llvm/llvm-project/blob/llvmorg-14.0.6/llvm/cmake/config-ix.cmake#L516
    REM and gets hardcoded by CMake to point to the path in our windows image.
    REM This makes it non-portable between image versions (e.g. 2019 vs 2022), so replace
    REM the hardcoded path with a variable again
    REM Updated to remove any assumptions about the edition or version of Visual Studio
    sed -i "s,[^\";]*DIA SDK/lib/amd64/diaguids\.lib,^$ENV{VSINSTALLDIR}/DIA SDK/lib/amd64/diaguids\.lib,g" %LIBRARY_LIB%\cmake\llvm\LLVMExports.cmake
)

rmdir /s /q temp_prefix