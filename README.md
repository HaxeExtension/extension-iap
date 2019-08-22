[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md) [![Haxelib Version](https://img.shields.io/github/tag/openfl/extension-iap.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/extension-iap) [![Build Status](https://img.shields.io/travis/openfl/extension-iap.svg?style=flat)](https://travis-ci.org/openfl/extension-iap)

## Fork changes:

- Change _openfl.utils.JNI_ -> _lime.system.JNI_
- build.gradle change dependencies methods
- Don't forget to rebuild the lib at first time!
- iOS: fix prices value bigger than 2147 (error with price in micros bigger than 4 bit max value number)

# IAP

Provides an access to in-app purchases (iOS) and in-app billing (Android) for OpenFL projects using a common API.

# Installation

You can easily install IAP using haxelib:

    haxelib install extension-iap

To add it to a Lime or OpenFL project, add this to your project file:

    <haxelib name="extension-iap" />

# Development Builds

Clone the IAP repository:

    git clone https://github.com/openfl/extension-iap

Tell haxelib where your development copy of IAP is installed:

    haxelib dev extension-iap extension-iap

You can build the binaries using "lime rebuild"

    lime rebuild extension-iap ios

To return to release builds:

    haxelib dev extension-iap
