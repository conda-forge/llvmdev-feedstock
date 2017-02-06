mkdir build
cd build

cmake -G "%CMAKE_GENERATOR%" ^
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

cmake --build . --config "%BUILD_CONFIG%"
if errorlevel 1 exit 1

cmake --build . --config "%BUILD_CONFIG%" --target install
if errorlevel 1 exit 1
