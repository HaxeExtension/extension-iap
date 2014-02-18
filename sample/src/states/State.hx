package states;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.BitmapData;
import com.emibap.core.ScreenUtils;

class State extends Sprite 
{

	public function new() 
	{
		super();
	}	

	public function start():Void {
		
	}
	
	public function stop():Void {
		
	}
	
	public function setBG(bgBmd:BitmapData, w:Int = 0, h:Int = 0):Void {
		if (bgBmd != null) {
			graphics.beginBitmapFill(bgBmd);
			graphics.drawRect(0, 0, (w == 0)? bgBmd.width : w, (h == 0)? bgBmd.height : h);
			graphics.endFill();
		} else {
			graphics.clear();
		}
	}

}