package ui;

import flash.display.Sprite;
import flash.display.BitmapData;
import flash.display.Bitmap; 
import flash.events.MouseEvent;
 
class BitmapButton extends Sprite {
	
	public var bitmap(default, null):Bitmap;
	
	var normalBmd:BitmapData;
	var downBmd:BitmapData;
	
	public function new (normalBmd:BitmapData, ?downBmd:BitmapData) {
		super();
		bitmap = new Bitmap(normalBmd);
		
		
		this.normalBmd = normalBmd;
		this.downBmd = downBmd;
		//bitmap.x = -bitmap.width * .5;
		//bitmap.y = -bitmap.height * .5;
		
		addChild(bitmap);
		setListeners();
	}		
	
	function setListeners() 
	{
		if (downBmd != null) {
			addEventListener(MouseEvent.MOUSE_DOWN, showDownState);
			addEventListener(MouseEvent.MOUSE_UP, showNormalState);
			addEventListener(MouseEvent.MOUSE_OUT, showNormalState);
		}
	}
	
	private function showNormalState(e:MouseEvent):Void 
	{
		bitmap.bitmapData = normalBmd;
	}
	
	private function showDownState(e:MouseEvent):Void 
	{
		bitmap.bitmapData = downBmd;
	}
	
	public var bitmapData(get, set):BitmapData;
	function get_bitmapData():BitmapData {
		return bitmap.bitmapData;
	}
	function set_bitmapData(bmd:BitmapData):BitmapData {
		return bitmap.bitmapData = bmd;
	}
	
	
	public function destroy():Void {
		bitmap.bitmapData = null;
		normalBmd = null;
		downBmd = null;
		bitmap = null;
		
		if (hasEventListener(MouseEvent.MOUSE_DOWN)) removeEventListener(MouseEvent.MOUSE_DOWN, showDownState);
		if (hasEventListener(MouseEvent.MOUSE_UP)) removeEventListener(MouseEvent.MOUSE_UP, showNormalState);
		if (hasEventListener(MouseEvent.MOUSE_OUT)) removeEventListener(MouseEvent.MOUSE_OUT, showNormalState);
	}
}
