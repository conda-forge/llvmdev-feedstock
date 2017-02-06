if "%ARCH%" == "32" (set PLATFORM=x86) else (set PLATFORM=x64)
call "%VS120COMNTOOLS%\..\..\VC\vcvarsall.bat" %PLATFORM%

mkdir build
cd build

cmake -G "NMake Makefiles" ^
    -DCMAKE_BUILD_TYPE="Release" ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
    -DLLVM_INCLUDE_TESTS=OFF ^
    -DLLVM_INCLUDE_UTILS=OFF ^
    -DLLVM_INCLUDE_DOCS=OFF ^
    -DLLVM_ENABLE_RTTI=ON ^
    -DLLVM_INCLUDE_EXAMPLES=OFF ^
    %SRC_DIR%

if errorlevel 1 exit 1

nmake
if errorlevel 1 exit 1

nmake install
if errorlevel 1 exit 1
