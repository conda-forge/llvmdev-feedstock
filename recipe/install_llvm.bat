@echo on

:: temporary prefix to be able to install files more granularly
mkdir temp_prefix

if "%PKG_NAME%" == "libllvm-c%PKG_VERSION:~0,2%" (
    cmake --install .\build --prefix=.\temp_prefix
    if %ERRORLEVEL% neq 0 exit 1
    REM only libLLVM-C
    move .\temp_prefix\bin\LLVM-C.dll %LIBRARY_BIN%
    move .\temp_prefix\lib\LLVM-C.lib %LIBRARY_LIB%
) else if "%PKG_NAME%" == "llvm-tools-%PKG_VERSION:~0,2%" (
    cmake --install ./build --prefix=./temp_prefix
    if %ERRORLEVEL% neq 0 exit 1

    REM all the executables (not .dll's) in \bin with a version suffix,
    REM except one binary that belongs to llvmdev
    del .\temp_prefix\bin\llvm-config.exe

    pushd .\temp_prefix\bin
    for %%f in (*.exe) do (
        echo %%~nf
        copy "%%~nf.exe" %LIBRARY_BIN%\%%~nf-%PKG_VERSION:~0,2%.exe
    )
    popd
) else if "%PKG_NAME%" == "llvm-tools" (
    cmake --install ./build --prefix=./temp_prefix
    if %ERRORLEVEL% neq 0 exit 1

    mkdir %LIBRARY_PREFIX%\share
    REM all the executables (not .dll's) in \bin & everything in \share
    move .\temp_prefix\share\* %LIBRARY_PREFIX%\share

    REM create wrappers (can't do symlinks on windows by default,
    REM needs to be compiled to be usable without extra ceremony)
    pushd .\temp_prefix\bin
    REM forwarder to call the versioned binary
    copy %RECIPE_DIR%\win_forwarder.c .\win_forwarder.c
    REM replace templated version number in code
    sed -i "s/{{ majorversion }}/%PKG_VERSION:~0,2%/g" .\win_forwarder.c
    REM the forwarder constructs the call based on its own filename,
    REM so we only need to compile it once...
    %CC% .\win_forwarder.c
    for %%f in (*.exe) do (
        REM .. and then create copies for each binary
        copy .\win_forwarder.exe %LIBRARY_BIN%\%%~nf.exe
    )
    popd
    del %LIBRARY_BIN%\llvm-config.exe
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
    sed -i "s,C:/Program Files/Microsoft Visual Studio/2022/Enterprise,$ENV{VSINSTALLDIR},g" %LIBRARY_LIB%\cmake\llvm\LLVMExports.cmake
)

rmdir /s /q temp_prefix
