cd build
cmake --build . --target install
if errorlevel 1 exit 1

if "%PKG_NAME%" == "llvm-tools" (
    del /f %LIBRARY_BIN%\*.dll
    rmdir /S /Q %LIBRARY_LIB%
    rmdir /S /Q %LIBRARY_INC%
    rmdir /S /Q %LIBRARY_PREFIX%\libexec
)

if "%PKG_NAME%" == "llvmdev" (
    set "FILE=%LIBRARY_LIB%\\cmake\\llvm\\LLVMExports-release.cmake"
    sed -i 's@'%LIBRARY_PREFIX%'@${_IMPORT_PREFIX}@g' %FILE%
    type %FILE%
)
