package com.emibap.ui;
import com.emibap.core.ScreenUtils;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;

class UIUtils
{
	
	static public function createTextField(w:Float = 100, h:Float = 40, fontSize:Float = 26, fontColor:Int = 0, fontBold:Bool = false, fontItalic:Bool = false):TextField {
		var res:TextField = new TextField();
		
		res.width = ScreenUtils.scaleFloat(w);
		res.height = ScreenUtils.scaleFloat(h);
		
		var tf:TextFormat = new TextFormat(null, cast ScreenUtils.scaleFloat(fontSize), fontColor, fontBold, fontItalic);
		
		res.defaultTextFormat = tf;
		
		return res;
		
		
	}
	
	static public function createSprBtn(label:String = "Btn", clickCB:MouseEvent->Void):Sprite {
		
		var txt:TextField = createTextField(290);
		txt.text = label;
		txt.x = ScreenUtils.scaleFloat(5);
		
		var spr = new Sprite();
		spr.addChild(txt);
		
		spr.mouseChildren = false;
		
		spr.graphics.beginFill(0xFF0000);
		spr.graphics.drawRect(0, 0, 300, 80);
		spr.graphics.endFill();
		
		spr.addEventListener(MouseEvent.CLICK, clickCB);
		
		return spr;
		
	}
}