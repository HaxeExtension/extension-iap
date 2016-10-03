@echo off
SET dir=%~dp0
cd %dir%
if exist extension-iap.zip del /F extension-iap.zip
winrar a -afzip extension-iap.zip extension haxelib.json include.xml dependencies ndll project
pause