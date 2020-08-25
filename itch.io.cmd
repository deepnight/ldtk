@echo off

REM echo -- PACKAGING RPG MAP --------------------------
REM haxelib run redistHelper hl.dx.hxml hl.sdl.hxml -o redist/itch.io res/changelog.md@CHANGELOG.txt redist/extras/README.txt redist/updateExtracter/neko@updater -hl32
REM if ERRORLEVEL 1 goto error
REM echo.

choice /C YN /M "Start uploading?"
if ERRORLEVEL 2 goto end
if ERRORLEVEL 1 goto upload
goto end


:upload
echo -- SENDING BUILDS --------------------------
butler push redist/LEd-win32-x64 deepnight/l-ed:win64

echo -- CHECKING ITCH.IO VERSIONS --------------------------
echo Please wait...
ping -n 6 localhost > nul
butler status deepnight/l-ed:win64
goto end


:error
echo.
echo FAILED!


:end
echo.
pause
exit