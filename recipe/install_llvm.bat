cd build
cmake --build . --target install
if errorlevel 1 exit 1

if "%PKG_NAME%" == "llvmdev" (
    del /f %LIBRARY_BIN\LLVM-*.dll
)
