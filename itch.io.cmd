@echo off

echo -- BUILDING APP --------------------------
cd app
call npm run pack

echo -- SENDING BUILDS --------------------------
butler push "redist/LEd installer.exe" deepnight/led:win64 --userversion-file ../lastBuildVersion.txt
goto end

:error
echo.
echo FAILED!
pause

:end
echo.
echo Done.
echo.
pause
exit
