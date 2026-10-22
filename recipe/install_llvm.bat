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
    del %LIBRARY_BIN%\llvm-config.exe
) else (
    REM llvmdev: everything else
    cmake --install .\build --prefix=%LIBRARY_PREFIX%
    if %ERRORLEVEL% neq 0 exit 1
)

rmdir /s /q temp_prefix
