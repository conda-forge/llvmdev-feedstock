@echo on
:: Must be fairly shallow
set DESTDIR=C:\llvmb
pushd build
  cmake --build . --target install
  if %errorlevel% neq 0 (
    echo "WARNING :: cmake --build . --target install failed, retrying"
    cmake --build . --target install
    if %errorlevel% neq 0 (
      echo "ERROR :: cmake --build . --target install failed, ignoring"
      :: echo "ERROR :: cmake --build . --target install failed, exiting"
      :: exit 1
    )
  )
  :: Drop drive letter and colon
  SET _PREFIX=%PREFIX:~2%

  pushd %DESTDIR%%_PREFIX%
    if "%PKG_NAME%" == "llvm-tools" (
      rmdir /S /Q Library\lib
      rmdir /S /Q Library\include
      rmdir /S /Q Library\libexec
      del /f Library\bin\*.dll
    )
    xcopy /S /Q /Y * %PREFIX%
  popd
popd
