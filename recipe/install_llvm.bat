cd build
cmake --build . --target install
if errorlevel 1 exit 1

if "%PKG_NAME%" == "llvm-tools" (
    del /f %LIBRARY_BIN%\*.dll
    rmdir /S /Q %LIBRARY_LIB%
    rmdir /S /Q %LIBRARY_INC%
)

if "%PKG_NAME%" == "llvm-utils" (
    cmake -DLLVM_INSTALL_UTILS=yes ..
    cmake --build . --target install
fi

