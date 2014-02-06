package extension.iap;

import flash.errors.Error;
import flash.events.EventDispatcher;
import flash.events.Event;
import flash.net.SharedObjectFlushStatus;
import flash.net.SharedObject;
import flash.Lib;
import haxe.Json;

#if android
import openfl.utils.JNI;
#end

typedef IAProduct = {
    productID: String,
    ?localizedTitle:String,
    ?localizedDescription:String,
    ?price:String,
    ?localizedPrice:String,
	?type:String		//android
}

@:allow(extension.iap) class IAP {
	
	
	public static var available (get, null):Bool;
	public static var manualTransactionMode (get, set):Bool;
	
	private static var dispatcher = new EventDispatcher ();
	private static var initialized = false;
	private static var items = new Map<String, Int> ();
	
	private static var tempProductsData:Array<IAProduct> = [];
	
	public static function addEventListener (type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		
		dispatcher.addEventListener (type, listener, useCapture, priority, useWeakReference);
		
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
		
		//trace("calling initialize");
		
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
			
			case "productsRestored":
				
				dispatchEvent (new IAPEvent (IAPEvent.PRODUCTS_RESTORED, data));
			
			case "productsRestoredWithErrors":
				
				dispatchEvent (new IAPEvent (IAPEvent.PRODUCTS_RESTORED_WITH_ERRORS, data));
			
			case "downloadStart":
				
				dispatchEvent (new IAPEvent (IAPEvent.DOWNLOAD_START,  Reflect.field (inEvent, "productID"), null, null,  Reflect.field (inEvent, "transactionID")));
			
			case "downloadProgress":
				
				var e:IAPEvent = new IAPEvent (IAPEvent.DOWNLOAD_PROGRESS,  Reflect.field (inEvent, "productID"), null, null,  Reflect.field (inEvent, "transactionID"));
				e.downloadPath = Reflect.field (inEvent, "downloadPath");
				e.downloadVersion = Reflect.field (inEvent, "downloadVersion");
				e.downloadProgress = Reflect.field (inEvent, "downloadProgress");
				dispatchEvent (e);
			
			case "downloadComplete":
				
				var e:IAPEvent = new IAPEvent (IAPEvent.DOWNLOAD_COMPLETE,  Reflect.field (inEvent, "productID"), null, null,  Reflect.field (inEvent, "transactionID"));
				e.downloadPath = Reflect.field (inEvent, "downloadPath");
				e.downloadVersion = Reflect.field (inEvent, "downloadVersion");
				dispatchEvent (e);
			
			case "productData":
				
				tempProductsData.push( { productID: Reflect.field (inEvent, "productID"), localizedTitle: Reflect.field (inEvent, "localizedTitle"), localizedDescription: Reflect.field (inEvent, "localizedDescription"), price: Reflect.field (inEvent, "price") } );
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA, Reflect.field (inEvent, "productID")));
			
			case "productDataComplete":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE, null, tempProductsData));
				tempProductsData.splice(0, tempProductsData.length);
			
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
	
	
	public static function finishTransactionManually (transactionID:String):Void {
		//TODO
		#if ios
			purchases_finish_transaction (transactionID);
		#end
	}
	
	public static function displayProductView (productID:String):Void {
		//TODO
	}
	
	public static function purchase (productID:String):Void {
		
		#if ios
		
		purchases_buy (productID);
		
		#elseif android	
		
		if (funcBuy == null) {
			
			funcBuy = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "buy", "(Ljava/lang/String;)V");
			
		}
		
		trace("calling purchase for " + productID);
		
		IAPHandler.lastPurchaseRequest = productID;
		funcBuy (productID);
		
		#end
			
	}
	
	public static function consume (purchase:Purchase):Void {
		
		#if ios
		
		if (hasPurchased (purchase.productID)) {
			
			items.set (purchase.productID, items.get (purchase.productID) - 1);
			save ();
			
		}
		
		#elseif android
		
		if (funcConsume == null) {
			
			funcConsume = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "consume", "(Ljava/lang/String;)V");
			
		}
		IAPHandler.lastPurchaseRequest = purchase.productID;
		funcConsume (purchase.originalJson);
		
		
		#end
		
	}
	
	public static function queryInventory (queryItemDetails:Bool = false, moreItems:Array<String> = null):Void {
		#if android
			if (funcQueryInventory == null) {
			
			funcQueryInventory = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "queryInventory", "(Z[Ljava/lang/String;)V");
			
		}
		
		//trace("calling queryInventory: queryItemDetails: " + queryItemDetails + " moreItems: " + moreItems);
		funcQueryInventory (queryItemDetails, moreItems);
		#end
	}
	
	public static function requestProductData (inArg:Dynamic):Void {
		
		#if ios
		
		var productID:String;
		
		tempProductsData.splice(0, tempProductsData.length);
		
		if (Std.is(inArg, String)) 
			purchases_get_data (cast(inArg, String));
		else if (Std.is(inArg, Array))
			purchases_get_data (cast(inArg, Array<Dynamic>).join(","));
		else
			throw new flash.errors.Error("Invalid parameter type: " + Type.typeof(inArg) + ". Valid types are String and Array<String>.");
		
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
		trace("getAvailable?");
		return purchases_canbuy ();
		
		#elseif android
		
		return IAPHandler.androidAvailable;
		
		#else
		
		return false;
		
		#end
		
	}
	
	public static function get_manualTransactionMode ():Bool {
		#if ios
		return purchases_get_manualtransactionmode ();
		#else
		return false;
		#end
	}
	public static function set_manualTransactionMode (val:Bool):Bool {
		#if ios
		purchases_set_manualtransactionmode (val);
		#else
		return false;
		#end
		
		return val;
	}
	
	
	// Native Methods
	
	
	
	
	#if android
	
	private static var funcInit:Dynamic;
	private static var funcBuy:Dynamic;
	private static var funcConsume:Dynamic;
	private static var funcRestore:Dynamic;
	private static var funcQueryInventory:Dynamic;
	private static var funcTest:Dynamic;
	
	#elseif ios
	
	private static var purchases_initialize = Lib.load ("iap", "iap_initialize", 0);
	private static var purchases_restore = Lib.load ("iap", "iap_restore", 0);
	private static var purchases_buy = Lib.load ("iap", "iap_buy", 1);
	private static var purchases_get_data = Lib.load ("iap", "iap_get_data", 1);
	private static var purchases_finish_transaction = Lib.load ("iap", "iap_finish_transaction", 1);
	private static var purchases_canbuy = Lib.load ("iap", "iap_canbuy", 0);
	private static var purchases_get_manualtransactionmode = Lib.load ("iap", "iap_get_manualtransactionmode", 0);
	private static var purchases_set_manualtransactionmode = Lib.load ("iap", "iap_set_manualtransactionmode", 1);
	private static var purchases_release = Lib.load ("iap", "iap_release", 0);
	private static var set_event_handle = Lib.load ("iap", "iap_set_event_handle", 1);
	
	#end
	
	
}


#if (android && !display)


private class IAPHandler {
	
	public static var lastPurchaseRequest:String = "";
	
	public static var androidAvailable:Bool = true;
	
	public function new () {
		
		
		
	}
	
	private function parseJsonResponse (response:Array<Dynamic>) :Dynamic {
		var strRes:String = "";

		if (Std.is(response, String)) {
			//trace("It's String!");
			strRes = cast (response, String);
		} else {
			trace("WARNING: Unexpected type for response parameter."); 
		}
		//trace("beforeParse: " + strRes);
		return Json.parse(strRes);
		
	}
	
	
	public function onCanceledPurchase (productID:String):Void {
		
		IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_CANCEL, productID));
		
	}
	
	
	public function onFailedConsume (response:Array<Dynamic>):Void
	{
		var productID:String = "";

		productID = lastPurchaseRequest; //temporal fix

		var dynResp:Dynamic = parseJsonResponse(response);
		
		//trace("Parsed!: " + dynResp);
		
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_CONSUME_FAILURE, productID);
		evt.productID = Reflect.field(Reflect.field(dynResp, "product"), "productId");
		evt.message = Reflect.field(Reflect.field(dynResp, "result"), "message");
		
		IAP.dispatcher.dispatchEvent (evt);
		
	}
	
	
	public function onConsume (response:Array<Dynamic>):Void
	{
		var productID:String = "";

		productID = lastPurchaseRequest; //temporal fix

		var dynResp:Dynamic = parseJsonResponse(response);
		
		//trace("Parsed!: " + dynResp);
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_CONSUME_SUCCESS);
		
		evt.productID = Reflect.field(dynResp, "productId");
		
		IAP.dispatcher.dispatchEvent (evt);
		
	}
	
	
	public function onFailedPurchase (response:Array<Dynamic>):Void
	{
		var productID:String = "";

		productID = lastPurchaseRequest; //temporal fix

		var dynResp:Dynamic = parseJsonResponse(response);
		
		//trace("Parsed!: " + dynResp);
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_FAILURE);
		if (Reflect.field(dynResp, "product") != null) evt.productID = Reflect.field(Reflect.field(dynResp, "product"), "productId");
		evt.message = Reflect.field(Reflect.field(dynResp, "result"), "message");
		
		IAP.dispatcher.dispatchEvent (evt);
		
	}
	
	
	public function onPurchase (response:Array<Dynamic>):Void 
	{
		//var productID:String = "";
		//productID = lastPurchaseRequest; //temporal fix

		
		//var dynResp:Dynamic = parseJsonResponse(response);
		
		//trace("Parsed!: " + dynResp);
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_SUCCESS);
		
		evt.purchase = new Purchase(response);
		evt.productID = evt.purchase.productID;
		
		IAP.dispatcher.dispatchEvent (evt);

	}
	
	public function onQueryInventoryComplete (response:Array<Dynamic>):Void {
		
		//trace("queryInventoryComplete: " + response);
				
		//trace(Type.getClass(response));
		//trace(Reflect.fields(response));
		
		var strRes:String = "";

		if (Std.is(response, String)) {
			//trace("It's String!");
			strRes = cast (response, String);
		}
		//if (Std.is(response, Int)) trace("It's  Int!");
		//if (Std.is(response, Float)) trace("It's  Float!");
		//if (Std.is(response, Dynamic)) {
			//trace("It's  Dynamic!");
		//}
		
		if (strRes == "Failure") {
			androidAvailable = false;
			IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_QUERY_INVENTORY_FAILED));
		} else {
			//trace("BeforeParse");

			var dynResp:Dynamic = Json.parse(strRes);
			//trace("Parsed!: " + dynResp);
			var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_QUERY_INVENTORY_COMPLETE);
			evt.productsData = new Array<IAProduct>();
			
			var dynDescriptions:Array<Dynamic> = Reflect.field(dynResp, "descriptions");
			var dynItmValue:Dynamic;
			var prod:IAProduct;
			
			if (dynDescriptions != null) {
				
				for (dynItm in dynDescriptions) {
					dynItmValue = Reflect.field(dynItm, "value");
					prod = { productID: Reflect.field(dynItmValue, "productId") };
					prod.type = Reflect.field(dynItmValue, "type");
					prod.localizedPrice = prod.price = Reflect.field(dynItmValue, "price");
					prod.localizedTitle = Reflect.field(dynItmValue, "title");
					prod.localizedDescription = Reflect.field(dynItmValue, "description");
					
					evt.productsData.push(prod);
				}
				
			}
			
			IAP.dispatcher.dispatchEvent (evt);
			
			androidAvailable = true;

			
			
		}
		
	}
	
	public function onRestorePurchases ():Void {
		
		IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_RESTORE));
		
	}
	
	
	public function onStarted (response:Array<Dynamic>):Void {
		//trace("onStarted: " + response);
				
		//trace(Type.getClass(response));
		//trace(Reflect.fields(response));
		
		if (cast(response, String) == "Success") {
			androidAvailable = true;
			IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT));
		} else {
			androidAvailable = false;
			IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT_FAILED));
		}
		
	}
	
	
}

#end