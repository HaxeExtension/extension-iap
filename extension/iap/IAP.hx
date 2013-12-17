package extension.iap;


import flash.events.EventDispatcher;
import flash.events.Event;
import flash.net.SharedObjectFlushStatus;
import flash.net.SharedObject;
import flash.Lib;

#if android
import openfl.utils.JNI;
#end


@:allow(extension.iap) class IAP {
	
	
	public static var available (get, null):Bool;
	
	private static var dispatcher = new EventDispatcher ();
	private static var initialized = false;
	private static var items = new Map<String, Int> ();
	
	
	public static function addEventListener (type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		
		dispatcher.addEventListener (type, listener, useCapture, priority, useWeakReference);
		
	}
	
	
	public static function consume (productID:String):Void {
		
		#if ios
		
		if (hasPurchased (productID)) {
			
			items.set (productID, items.get (productID) - 1);
			save ();
			
		}
		
		#end
		
	}
	
	
	public static function dispatchEvent (event:Event):Bool {
		
		return dispatcher.dispatchEvent (event);
		
	}
	
	
	
	
	
	public static function getQuantity (productID:String):Int {
		
		#if ios
		
		if (hasPurchased (productID)) {
			
			return items.get (productID);
			
		}
		
		#end
		
		return 0;
		
	}
	

	
	
	public static function hasEventListener (type:String):Bool {
		
		return dispatcher.hasEventListener (type);
		
	}
	
	
	public static function hasPurchased (productID:String):Bool {
		
		#if ios
		
		if (items == null) {
			
			return false;
			
		}
		
		return items.exists (productID) && items.get (productID) > 0;
		
		#else
		
		return false;
		
		#end
		
	}
	
	
	public static function initialize (publicKey:String = ""):Void {
		
		#if ios
		
		if (!initialized) {
			
			set_event_handle (notifyListeners);
			load ();
			
			initialized = true;
			
		}
		
		purchases_initialize ();
		
		#elseif android
		
		if (funcInit == null) {
			
			funcInit = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "initialize", "(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V");
			load ();
			
		}
		
		funcInit (publicKey, new IAPHandler ());
		
		#end
		
	}
	
	
	private static function load ():Void {
		
		try {
			
			var data = SharedObject.getLocal ("in-app-purchases");
			var saveData = Reflect.field (data.data, "data");
			
			if (saveData != null) {
				
				items = saveData;
				//trace (items);
				
			}
			
		} catch (e:Dynamic) {
			
			trace ("ERROR: Could not load purchases: " + e);
			
		}
		
	}
	
	
	private static function notifyListeners (inEvent:Dynamic):Void {
		
		#if ios
		
		var type = Std.string (Reflect.field (inEvent, "type"));
		var data = Std.string (Reflect.field (inEvent, "data"));
		
		switch (type) {
			
			case "started":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT, data));
				
			case "success":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_SUCCESS, data));
			
			case "failed":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_FAILURE, data));
			
			case "cancel":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_CANCEL, data));
			
			case "restore":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_RESTORE, data));
			
			case "productData":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA, (Reflect.field (inEvent, "productID")), (Reflect.field (inEvent, "localizedTitle")), (Reflect.field (inEvent, "localizedDescription")), (Reflect.field (inEvent, "price"))));
			
			case "productDataComplete":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE));
			
			default:
			
		}
		
		// Consumable
		
		if (type == "success") {
			
			var productID = data;
			
			if (hasPurchased (productID)) {
				
				items.set (productID, items.get (productID) + 1);
				
			} else {
				
				items.set (productID, 1);
				
			}
			
			save ();
			
		}
		
		#end
		
	}
	
	
	public static function purchase (productID:String):Void {
		
		#if ios
		
		purchases_buy (productID);
		
		#elseif android	
		
		if (funcBuy == null) {
			
			funcBuy = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "buy", "(Ljava/lang/String;)V");
			
		}
		IAPHandler.lastPurchaseRequest = productID;
		funcBuy (productID);
		
		#end
			
	}
	
	
	public static function requestProductData (productID:String):Void {
		
		#if ios
		
		purchases_get_data (productID);
		
		#elseif android	
		
		#end
			
	}
	
	
	private static function registerHandle ():Void {
		
		#if ios
		
		set_event_handle (notifyListeners);
		
		#end
		
	}
	
	
	private static function release ():Void {
		
		#if ios
		
		purchases_release ();
		
		#end
		
	}
	
	
	public static function removeEventListener (type:String, listener:Dynamic, capture:Bool = false):Void {
		
		dispatcher.removeEventListener (type, listener, capture);
		
	}
	
	
	public static function restorePurchases ():Void {
		
		#if ios
		
		purchases_restore ();
		
		#elseif android
		//
		//if (funcRestore == null) {
		//	
		//	funcRestore = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "restore", "()V");
		//	
		//}
		//
		//funcRestore ();
		
		#end
		
	}
	
	
	private static function save ():Void {
		
		var so = SharedObject.getLocal ("in-app-purchases");
		Reflect.setField (so.data, "data", items);
		
		#if (cpp || neko)
		
		var flushStatus:SharedObjectFlushStatus = null;
		
		try {
			
			flushStatus = so.flush ();
			
		} catch (e:Dynamic) {
			
			trace ("ERROR: Failed to save purchases: " + e);
			
		}
		
		/*if (flushStatus != null) {
			
			switch (flushStatus) {
				
				case SharedObjectFlushStatus.PENDING: trace ("Requesting permission to save purchases");
				case SharedObjectFlushStatus.FLUSHED: trace ("Saved purchases");
				default:
				
			}
			
		}*/
		
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_available ():Bool {
		
		#if ios
		return purchases_canbuy ();
		
		#elseif android
		
		return true;
		
		#else
		
		return false;
		
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if android
	
	private static var funcInit:Dynamic;
	private static var funcBuy:Dynamic;
	private static var funcRestore:Dynamic;
	private static var funcTest:Dynamic;
	
	#elseif ios
	
	private static var purchases_initialize = Lib.load ("iap", "iap_initialize", 0);
	private static var purchases_restore = Lib.load ("iap", "iap_restore", 0);
	private static var purchases_buy = Lib.load ("iap", "iap_buy", 1);
	private static var purchases_get_data = Lib.load ("iap", "iap_get_data", 1);
	private static var purchases_canbuy = Lib.load ("iap", "iap_canbuy", 0);
	private static var purchases_release = Lib.load ("iap", "iap_release", 0);
	private static var set_event_handle = Lib.load ("iap", "iap_set_event_handle", 1);
	
	#end
	
	
}


#if (android && !display)


private class IAPHandler {
	
	public static var lastPurchaseRequest:String = "";
	
	public function new () {
		
		
		
	}
	
	
	public function onCanceledPurchase (productID:String):Void {
		
		IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_CANCEL, productID));
		
	}
	
	
	public function onFailedPurchase (dataProductID:Array<Dynamic>):Void
	{
		var productID:String = "";

		productID = lastPurchaseRequest; //temporal fix

		
		IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_FAILURE, productID));
		
	}
	
	
	public function onPurchase (dataProductID:Array<Dynamic>):Void 
	{
		var productID:String = "";
		productID = lastPurchaseRequest; //temporal fix

		IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_SUCCESS, productID));

	}
	
	
	public function onRestorePurchases ():Void {
		
		IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_RESTORE));
		
	}
	
	
	public function onStarted (msg:Array<Dynamic>):Void {
		
		IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT));
		
	}
	
	
}

#end