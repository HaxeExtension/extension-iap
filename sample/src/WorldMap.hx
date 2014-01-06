package ;

import com.emibap.core.ScreenUtils;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.Lib;
import model.GameModel;
import model.GameUserData;

import flash.text.TextField;

import extension.iap.IAP;
import extension.iap.IAPEvent;

class WorldMap extends Sprite
{

	// Callbacks/Handlers
	public var onElementSelected:MapElement->Void;
	

	public var lastSelectedElement(default, null):MapElement;
	
	var bgBmp:Bitmap;
	
	var model:GameModel;
	var userData:GameUserData;
	
	var container:Sprite;
	
	
	public function new(mdl:GameModel) 
	{
		super();
		
		model = mdl;
		userData = GameUserData.getInstance();
		init();
		
	}
	
	function init() 
	{
		
		container = new Sprite();
		addChild(container);
		
		setBG(model.bgBmd);
		
		addElements();
	}
	
	function addElements() 
	{
		for (wel in userData.worldElements.iterator()) {
			if (wel.type != "fixed") wel.addEventListener(MouseEvent.CLICK, elementSelected);
			container.addChild(wel);
			container.addChild(wel);
		}
	}
	
	private function elementSelected(e:MouseEvent):Void 
	{
		//var wel:MapElement = cast e.target;
		//trace("selected: " + wel.id);
		
		lastSelectedElement = cast e.target;
		
		if (onElementSelected != null) onElementSelected(lastSelectedElement);
		
		//presentElementOptions(wel);
		
	}
	
	function setBG(bitmapData:BitmapData) 
	{
		if (bgBmp == null) bgBmp = new Bitmap(bitmapData);
		container.addChildAt(bgBmp, 0);
		
		centerBG();
	}
	
	function centerBG() 
	{
		container.x = ScreenUtils.applicationWidth / 2 - bgBmp.width / 2;
		container.y = ScreenUtils.applicationHeight / 2 - bgBmp.height / 2;
	}
	
}