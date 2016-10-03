#!/bin/bash
dir=`dirname "$0"`
cd "$dir"
haxelib remove extension-iap
haxelib local extension-iap.zip
