@echo on

REM Note that we don't build a dll for windows at the moment, meaning the libllvm package is an empty package. It was
REM done like this to avoid having to have `- libllvm # [not win]` everywhere. There's an LLVM-c.dll, which implements
REM the C (but not C++) API, which can be built if we have -DLLVM_BUILD_LLVM_C_DYLIB=ON at the build stage. LLVM .dlls
REM are used for e.g. JIT compilation, which we don't need at the moment on Windows. See the conda-forge recipe for an
REM example of building and packaging this dll if we do need it.

:: temporary prefix to be able to install files more granularly
mkdir temp_prefix

if "%PKG_NAME%" == "llvm-tools" (
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
)

rmdir /s /q temp_prefix