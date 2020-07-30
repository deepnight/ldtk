@echo off
rmdir redist /S /Q
cd app
call npm i electron-packager --save-dev
call npm i electron --save-dev
call electron-packager . LEd --platform=win32 --arch=ia32,x64  --overwrite --out=../redist
pause
