cd build
cmake --build . --target install
if errorlevel 1 exit 1

if "%PKG_NAME%" == "llvm-tools" (
    del /f %LIBRARY_BIN%\*.dll
    del /f %LIBRARY_LIB%
    del /f %LIBRARY_INC%
)
