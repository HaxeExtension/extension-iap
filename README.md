[![Haxelib Version](https://img.shields.io/github/tag/openfl/iap.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/iap) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md) [![Build Status](https://img.shields.io/travis/openfl/iap.svg?style=flat)](https://travis-ci.org/openfl/iap)

IAP
===
Provides an access to in-app purchases (iOS) and in-app billing (Android) for OpenFL projects using a common API.


Installation
============

You can easily install IAP using haxelib:

    haxelib install iap

To add it to a Lime or OpenFL project, add this to your project file:

    <haxelib name="iap" />


Development Builds
==================

Clone the IAP repository:

    git clone https://github.com/openfl/iap

Tell haxelib where your development copy of IAP is installed:

    haxelib dev iap iap

You can build the binaries using "lime rebuild"

    lime rebuild iap ios

To return to release builds:

    haxelib dev iap
