@echo off
SET dir=%~dp0
cd %dir%
haxelib remove extension-iap
haxelib local extension-iap.zip
