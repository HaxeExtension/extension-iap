#!/bin/bash
dir=`dirname "$0"`
cd "$dir"
rm -rf project/obj
lime rebuild . ios
rm -rf project/obj
rm -f extension-iap.zip
zip -9r extension-iap.zip extension haxelib.json include.xml dependencies ndll project
