package com.emibap.ui;
import com.emibap.core.ScreenUtils;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.text.TextField;

class MessageBox
{
	private static var root:Sprite;

	private static var msg:Sprite;
	private static var msgPill:Sprite;
	private static var modalMask:Sprite;
	private static var OKBtn:Sprite;
	private static var mainText:TextField;
	private static var dispatcher = new EventDispatcher ();
	
	public static var EVT_OK :String = "msg_ok";
	
	public static function addEventListener (type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		
		dispatcher.addEventListener (type, listener, useCapture, priority, useWeakReference);
		
	}
	public static function dispatchEvent (event:Event):Bool {
		
		return dispatcher.dispatchEvent (event);
		
	}
	
	public static function initialize(rt:Sprite):Void {
		root = rt;
		if (msg == null) {
			msg = new Sprite();
			msgPill = new Sprite();
			modalMask = new Sprite();
			modalMask.graphics.beginFill(0, 0.1);
			modalMask.graphics.drawRect(0, 0, 256, 256);
			modalMask.graphics.endFill();
			//modalMask.addEventListener(MouseEvent.CLICK, doNothing);
			//modalMask.useHandCursor = false;
			
			mainText = UIUtils.createTextField(300, 50);
			mainText.mouseEnabled = false;
			
			msgPill.addChild(mainText);
			
			OKBtn = UIUtils.createSprBtn("OK", onOKPressed);
			OKBtn.x = msgPill.width / 2 - OKBtn.width / 2;
			OKBtn.y = 80;
			
			msg.addChild(modalMask);
			msg.addChild(msgPill);
			
		}
	}
	
	private static function onOKPressed(e:MouseEvent) 
	{
		trace("OK Pressed");
		hideModal();
		dispatchEvent(new Event(EVT_OK));
	}
	
	/*private static function doNothing(e:MouseEvent):Void 
	{
		trace("ModalTouch");
	}*/
	
	public static function showModal(txt:String):Void {
		centerModal();
		mainText.text = txt;
		
		if (!msgPill.contains(OKBtn)) msgPill.addChild(OKBtn);
		
		root.addChild(msg);
	}
	
	public static function showCustomModal(panel:Sprite):Void {
		centerModal(panel);
		
		root.addChild(panel);
	}
	
	public static function hideModal(?panel:Sprite):Void {
		if (root.contains(msg)) root.removeChild(msg);
		if ((panel != null) && root.contains(panel)) root.removeChild(panel);
	}
	
	private static function centerModal(?panel:Sprite) 
	{
		modalMask.width = ScreenUtils.applicationWidth;
		modalMask.height = ScreenUtils.applicationHeight;
		msgPill.x = modalMask.width / 2 - msgPill.width / 2;
		msgPill.y = modalMask.height / 2 - msgPill.height / 2;
		
		if (panel != null) {
			panel.x = modalMask.width / 2 - panel.width / 2;
			panel.y = modalMask.height / 2 - panel.height / 2;
		}
		
		
		
	}
	
}