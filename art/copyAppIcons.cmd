@echo off

where /q aseprite.exe
if ERRORLEVEL 1 (
    echo You need ASEPRITE.EXE in PATH for this script to work.
    goto end
)

echo Copying app icon...
copy /Y "OS icons-assets\appIcon.png" ..\app\assets\ >nul

echo Converting OS icons to ICO...
aseprite -b "OS icons-assets\appIcon.png" --save-as ..\app\buildAssets\icon.ico
aseprite -b "OS icons-assets\level.png" --save-as ..\app\buildAssets\level.ico
aseprite -b "OS icons-assets\project.png" --save-as ..\app\buildAssets\project.ico
echo Done.
goto end

:end
echo.
pause
exit /b
