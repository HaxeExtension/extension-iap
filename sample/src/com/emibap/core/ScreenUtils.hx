package com.emibap.core;
import flash.display.Stage;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.system.Capabilities;
import flash.text.TextField;
import flash.text.TextFormat;
import openfl.Assets;
import flash.display.BitmapData;

class ScreenUtils
{
	public static inline var SIZE_DPI_RELATION:Float = 1280.4;
	public static inline var BASE_WIDTH:Float = 1024;
	
	public static var needsScaling:Bool = false;
	public static var matrix:Matrix;
	public static var scale:Float;
	public static var applicationWidth:Int;
	public static var applicationHeight:Int;
	// For DrawingsFactory
	public static var drwBaseWidth:Float;
	
	private static var _buttonExceedHA:BitmapData;
	
	public static function setScaleMatrix():Void
	{			
		/**
		 * DPIs: http://en.wikipedia.org/wiki/List_of_displays_by_pixel_density
		 
		iPhone 4S / iPod Touch	4S / 4th Gen	8.9 (3.5 inches)	960×640	128 (326)		3:2
		iPhone 5 / iPod Touch	5 / 5th Gen	10 (4 inches)			1136×640	128 (326)	71:40
		
		iPad mini	Original	20 (7.9 inches)						1024×768	64 (163)	4:3
		iPad	Original, 2	25 (9.7 inches)							1024×768	52 (132)	4:3
		iPad with Retina Display	3rd, 4th Gen	25 (9.7 inches)	2048×1536	104 (264)	4:3
		
		BlackBerry PlayBook	18 (7)									1024×600	67 (169)	15:9–16:9	1
		BlackBerry 10 Dev Alpha	11 (4.2)							1280×768	140 (356)	15:9–16:9	
		
		
		Kindle Fire HD 8.9"[3]	23 (8.9)	1920x1200	100 (254)	16:10	1.5
		Kindle Fire HD 7"[4]	18 (7)	1280x800	85 (216)	16:10	1.5
		Kindle Fire[5]	18 (7)	1024×600	67 (169)	5.12:3
		 
		 */
		
		//Code for SWF output

		#if (cpp || neko)
		applicationWidth = Std.int(Capabilities.screenResolutionX);
		applicationHeight = Std.int(Capabilities.screenResolutionY);
		#end
		
		//Dirty Hack for flash
		#if (flash && DEVICE_IPAD)
		applicationWidth = 1024;
		applicationHeight = 768;
		#end
		#if (flash && (DEVICE_IPHONE4))
		applicationWidth = 960;
		applicationHeight = 640;
		#end
		#if (flash && (DEVICE_IPHONE5))
		applicationWidth = 1136;
		applicationHeight = 640;
		#end
		
		// Highest value for width (?)
		if (applicationWidth < applicationHeight) {
			var tempVal:Int = applicationWidth;
			applicationWidth = applicationHeight;
			applicationHeight = tempVal;
		}
		
		if (applicationWidth > 1280) {
			scale = applicationWidth / BASE_WIDTH;
			drwBaseWidth = BASE_WIDTH * 2;
		} else {
			scale = 1;
			drwBaseWidth = BASE_WIDTH;
		}
		
		needsScaling = (scale != 1);
	}
	
	public static function getBitmapData(str:String, useCache:Bool=true) :BitmapData {
		if (needsScaling == false) return Assets.getBitmapData(str, useCache);
		else return Assets.getBitmapData(str.split(".").join("@2x."), useCache);
	}
	
	public static inline function scaleFloat(val:Float):Float {
		return val*scale;
	}
	public static inline function scaleInt(val:Int):Int {
		return Std.int(val*scale);
	}
	
	public static var isIpad(get_isIpad, null):Bool;
	static function get_isIpad():Bool {
		#if cpp
		return ((applicationWidth == 1024 && applicationHeight == 768) || (applicationWidth == 2048 && applicationHeight == 1536));
		#end
		#if DEVICE_IPAD
		return true;
		#else
		return false;
		#end
	}
	public static var isIphone4(get_isIphone4, null):Bool;
	static function get_isIphone4():Bool {
		#if cpp
		return (applicationWidth == 960 && applicationHeight == 640);
		#end
		#if DEVICE_IPHONE4
		return true;
		#else
		return false;
		#end
	}
	public static var isIphone5(get_isIphone5, null):Bool;
	static function get_isIphone5():Bool {
		#if cpp
		return (applicationWidth == 1136 && applicationHeight == 640);
		#end
		#if DEVICE_IPHONE5
		return true;
		#else
		return false;
		#end
	}
	
	public static function exceedButtonHitArea(b:Sprite, px:Int = 20):BitmapData {
		if (_buttonExceedHA == null) {
			_buttonExceedHA = new BitmapData(Std.int(b.width) + px*2, Std.int(b.height) + px*2, true, 0);
		}
		return _buttonExceedHA;
	}
}
