@echo off
cd app
copy package.nwjs.json package.json /Y
nw .
exit