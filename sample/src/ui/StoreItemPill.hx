package ui;
import com.emibap.core.ScreenUtils;
import com.emibap.ui.UIUtils;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

class StoreItemPill extends Sprite
{
	public var id(default, null):String;
	var highlight:Sprite;
	var selectedBmp:Bitmap;
	var description_txt:TextField;
	var thumb:Bitmap;
	
	public function new(id:String = "", thmbBmd:BitmapData, desc:String) 
	{
		super();
		
		this.id = id;
		createRoundShape(this, 0x939292, 50);
		
		highlight = new Sprite();
		highlight.mouseEnabled = false;
		createRoundShape(highlight, 0x92c8cc, 50);
		
		selectedBmp = new Bitmap(ScreenUtils.getBitmapData("img/item_hover.png"));
		
		thumb = new Bitmap(thmbBmd);
		thumb.x = thumb.y = selectedBmp.x = selectedBmp.y = ScreenUtils.scaleFloat(4);
		description_txt = UIUtils.createTextField(68, 44, 12);
		var fmt:TextFormat = description_txt.defaultTextFormat;
		fmt.align = TextFormatAlign.CENTER;
		description_txt.wordWrap = true;
		description_txt.defaultTextFormat = fmt;
		
		
		description_txt.x = ScreenUtils.scaleFloat(2);
		description_txt.y = thumb.y + thumb.height;
		description_txt.text = desc;
		description_txt.mouseEnabled = false;
		
		
		addChild(thumb);
		addChild(description_txt);
		setListeners();
	}
	
	function setListeners() 
	{
		addEventListener(MouseEvent.MOUSE_DOWN, doHighlight);
		addEventListener(MouseEvent.MOUSE_OUT, doBackToNormal);
		addEventListener(MouseEvent.MOUSE_UP, doBackToNormal);
	}
	
	private function doBackToNormal(e:MouseEvent):Void 
	{
		if (contains(highlight)) removeChild(highlight);
		if (contains(selectedBmp)) removeChild(selectedBmp);
	}
	
	private function doHighlight(e:MouseEvent):Void 
	{
		
		if (!contains(highlight)) {
			addChildAt(highlight, 0);
			if (!contains(selectedBmp)) addChild(selectedBmp);
		}
	}
	
	function createRoundShape(dsp:Sprite, color:Int, alpha:Float):Void {
		
		dsp.graphics.beginFill(color, alpha);
		dsp.graphics.drawRoundRect(0, 0, ScreenUtils.scaleFloat(72), ScreenUtils.scaleFloat(128), ScreenUtils.scaleInt(16), ScreenUtils.scaleInt(16));
		dsp.graphics.endFill();
	}
	
}