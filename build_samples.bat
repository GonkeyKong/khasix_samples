@echo off

set root_dir=%cd%
set bin_dir=%root_dir%\bin
set khasix_src_dir=%root_dir%\khasix
set src_dir=%root_dir%

if not exist %bin_dir% mkdir %bin_dir%

set sample=%1
if "%sample%"=="" (
  echo No sample provided.
  exit /b 1
)

echo Building: %sample%
set sample=%src_dir%\%sample%
if not exist %sample% (
  echo Sample does not exist.
  exit /b 1
)

pushd %bin_dir%

set cc=odin build %sample% -file -debug -collection:khasix=%khasix_src_dir%
echo %cc%
%cc%

popd
