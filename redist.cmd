@echo off
echo.

echo Cleaning up existing redists...
rmdir app\redist /S /Q
echo.

echo Compiling app...
haxe app.hxml
echo.

cd app

echo.
echo Packaging...
call npm run build

echo.
echo Copying version file...
copy ..\buildVersion.txt redist >NUL

cd ..

echo.
echo Done.
echo.
