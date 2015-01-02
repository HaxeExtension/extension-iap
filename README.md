[![Stories in Ready](https://badge.waffle.io/openfl/iap.png?label=ready)](https://waffle.io/openfl/iap)
[![Build Status](https://travis-ci.org/openfl/iap.png)](https://travis-ci.org/openfl/iap)
IAP
===

Provides access to in-app purchases (iOS) and in-app billing (android) for OpenFL projects, using a common API.


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