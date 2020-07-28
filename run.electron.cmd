@echo off
cd app
copy package.electron.json package.json /Y
electron .
exit