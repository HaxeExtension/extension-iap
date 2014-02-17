package extension.iap;

import flash.errors.Error;
import flash.events.EventDispatcher;
import flash.events.Event;
import flash.Lib;
import haxe.Json;

#if android
import openfl.utils.JNI;
#end


/**
 * Provides convenience methods and properties for in-app purchases (Android & iOS).
 * The methods and properties are static, so there's no need to instantiate an instance, 
 * but an initialization is required prior to the first use.
 * Every method is asynchronous (non-blocking). The callbacks always fire events indicating 
 * the success or failure of every operation.
 *
 * The first step is to initialize the extension. You do so by calling the {@link #initialize} 
 * method. The result comes with a PURCHASE_INIT or PURCHASE_INIT_FAILED IAPEvent. Also, the
 * available property will tell if you can use the extension at any time.
 * 
 * Although we aim to provide a unified API for every target, there are some differences that
 * required to leave platform exclusive methods and properties. So you'll find different workflows.
 *
 * Android workflow:
 * ----------------
 * 
 * After initialization is complete, you will typically want to request an inventory of owned 
 * items and subscriptions. See {@link #queryInventory} and related events. This method can also be
 * used to retrieve a detailed list of products.
 * 
 * Then you may want to buy items with the {@link #purchase} method, and if the item is consumable, 
 * the {@link #consume} method should be called after a successful purchase. 
 *
 * iOS workflow:
 * ------------
 * 
 * After initialization is complete, you will typically want request details about the products 
 * being sold {@link #requestProductData}, and also probably try to restore non consumable 
 * items previously purchased by the user using the {@link #restore} method.
 * 
 * Then you may want to buy items with the {@link #purchase} method. You don't need to call the
 * consume method for iOS.
 *
 * You may want to check the IAPEvent, Purchase and ProductDetails classes to explore further.
 * 
 */



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
	
	public static var inventory(get, null):Inventory = null;
	
	private static var initialized = false;
	
	private static var tempProductsData:Array<IAProduct> = [];
	
	// Event dispatcher composition
	private static var dispatcher = new EventDispatcher ();
	
	
	/**
     * Initializes the extension. 
	 * 
     * @param publicKey (Android). Your application's public key, encoded in base64. 
     *     This is used for verification of purchase signatures. You can find your app's base64-encoded 
     *     public key in your application's page on Google Play Developer Console. Note that this
     *     is NOT your "developer public key".
	 * 
	 * Related Events (IAPEvent): 
	 * 		PURCHASE_INIT: Fired when the initialization was successful
	 * 		PURCHASE_INIT_FAILED: Fired when the initialization failed
     */
	
	public static function initialize (publicKey:String = ""):Void {
		
		#if ios
		
		if (!initialized) {
			
			inventory = new Inventory(null);
			
			set_event_handle (notifyListeners);
			
			initialized = true;
			
		}
		
		purchases_initialize ();
		
		#elseif android
		
		if (funcInit == null) {
			
			funcInit = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "initialize", "(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V");
			
		}
		
		//trace("calling initialize");
		
		if (inventory == null) inventory = new Inventory(null);
		
		funcInit (publicKey, new IAPHandler ());
		
		#else
		
		dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT_FAILED, null));
		
		#end
		
	}
	
	/**
     * Sends a purchase intent for a given product.
	 * 
     * @param productID (iOS & Android). The unique Id for the desired product (Android Sku).
	 * @param devPayload (Android). Extra data (developer payload), which will be returned with the purchase data
     *     when the purchase completes. This extra data will be permanently bound to that purchase
     *     and will always be returned when the purchase is queried.
	 * 
	 * Related Events (IAPEvent): 
	 * 		PURCHASE_SUCCESS: Fired when the purchase attempt was successful
	 * 		PURCHASE_FAILURE: Fired when the purchase attempt failed
	 * 		PURCHASE_CANCEL: Fired when the purchase attempt was cancelled by the user
     */
	
	public static function purchase (productID:String, devPayload:String = ""):Void {
		
		#if ios
		
		purchases_buy (productID);
		
		#elseif android	
		
		if (funcBuy == null) {
			
			funcBuy = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "buy", "(Ljava/lang/String;Ljava/lang/String;)V");
			
		}
		
		//trace("calling purchase for " + productID + " - payload: " + devPayload);
		
		IAPHandler.lastPurchaseRequest = productID;
		funcBuy (productID, devPayload);
		
		#end
			
	}
	
	
	
	// Android only methods
	
	/**
     * Sends a consume intent for a given product.
	 * 
     * @param purchase. The previously purchased product.
	 * 
	 * Related Events (IAPEvent): 
	 * 		PURCHASE_CONSUME_SUCCESS: Fired when the consume attempt was successful
	 * 		PURCHASE_CONSUME_FAILURE: Fired when the consume attempt failed
     */
	
	public static function consume (purchase:Purchase):Void {
		
		#if android
		
		if (funcConsume == null) {
			
			funcConsume = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "consume", "(Ljava/lang/String;)V");
			
		}
		IAPHandler.lastPurchaseRequest = purchase.productID;
		funcConsume (purchase.originalJson);
		
		
		#end
		
	}
	
	
	/**
     * Queries the inventory. This will query all owned items from the server, as well as
     * information on additional products, if specified.
     *
     * @param queryItemDetails if true, product details (price, description, etc) will be queried as well
     *     as purchase information.
     * @param moreItems additional PRODUCT IDs to query information on, regardless of ownership. 
     *     Ignored if null or if queryItemDetails is false.
	 * 
	 * Related Events (IAPEvent): 
	 * 		PURCHASE_QUERY_INVENTORY_COMPLETE: Fired when the query inventory attempt was successful. 
	 * 			The inventory static property will be populated with new data.
	 * 		PURCHASE_QUERY_INVENTORY_FAILED: Fired when the query inventory attempt failed
     */
	
	public static function queryInventory (queryItemDetails:Bool = false, moreItems:Array<String> = null):Void {
		#if android
			if (funcQueryInventory == null) {
			
			funcQueryInventory = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "queryInventory", "(Z[Ljava/lang/String;)V");
			
		}
		
		//trace("calling queryInventory: queryItemDetails: " + queryItemDetails + " moreItems: " + moreItems);
		funcQueryInventory (queryItemDetails, moreItems);
		#end
	}
	
	
	
	// iOS only methods
	
	
	/**
     * Retrieves localized information about a list of products.
	 * 
     * @param inArg. A String with the product Id, or an Array of Strings with multiple product Ids.
	 * 
	 * Related Events (IAPEvent): 
	 * 		PURCHASE_PRODUCT_DATA_COMPLETE: Fired when the products data has been retrieved. 
	 * 			The event will come with a productsData array.
	 * 			This method also populates the productDetailsMap property of the inventory, so it can be accessed anytime after calling it.
     */
	
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
	
	/**
     * Asks the payment queue to restore previously completed purchases.
	 * 
	 * Related Events (IAPEvent): 
	 * 		PRODUCTS_RESTORED: Fired when the restore process has successfully finished.
	 * 		PRODUCTS_RESTORED_WITH_ERRORS: Fired when the restore process finished with errors.
     */
	
	public static function restorePurchases ():Void {
		
		#if ios
		
		purchases_restore ();
		
		#end
		
	}
	
	
	
	
	public static function finishTransactionManually (transactionID:String):Void {
		#if ios
			purchases_finish_transaction (transactionID);
		#end
	}
	
	
	public static function release ():Void {
		
		#if ios
		
		purchases_release ();
		
		#end
		
	}
	
	//TODO
	/*public static function displayProductView (productID:String):Void {
		
	}*/
	
	
	// Private Static Methods
	
	
	private static function registerHandle ():Void {
		
		#if ios
		
		set_event_handle (notifyListeners);
		
		#end
		
	}

	
	private static function notifyListeners (inEvent:Dynamic):Void {
		
		#if ios
		
		var type = Std.string (Reflect.field (inEvent, "type"));
		var data = Std.string (Reflect.field (inEvent, "data"));
		
		switch (type) {
			
			case "started":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT, data));
			
			case "success":
				
				var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_SUCCESS);
				evt.purchase = new Purchase(inEvent);
				evt.productID = evt.purchase.productID;
				inventory.set(evt.purchase.productID, evt.purchase);
				
				dispatchEvent (evt);
			
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
				var prod:IAProduct = { productID: Reflect.field (inEvent, "productID"), localizedTitle: Reflect.field (inEvent, "localizedTitle"), localizedDescription: Reflect.field (inEvent, "localizedDescription"), price: Reflect.field (inEvent, "price") };
				tempProductsData.push(prod );
				
				inventory.productDetailsMap.set(prod.productID, new ProductDetails(prod));
				
			case "productDataComplete":
				
				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE, null, tempProductsData));
				tempProductsData.splice(0, tempProductsData.length);
			
			default:
			
		}
		
		#end
		
	}
	
	
	// Getter & Setter Methods
	
	
	private static function get_available ():Bool {
		
		#if ios
		return purchases_canbuy ();
		
		#elseif android
		
		return IAPHandler.androidAvailable;
		
		#else
		
		return false;
		
		#end
		
	}
	
	private static function get_manualTransactionMode ():Bool {
		#if ios
		return purchases_get_manualtransactionmode ();
		#else
		return false;
		#end
	}
	
	private static function set_manualTransactionMode (val:Bool):Bool {
		#if ios
		purchases_set_manualtransactionmode (val);
		#else
		return false;
		#end
		
		return val;
	}
	
	
	
	// Event Dispatcher composition methods
	
	public static function addEventListener (type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		
		dispatcher.addEventListener (type, listener, useCapture, priority, useWeakReference);
		
	}

	public static function removeEventListener (type:String, listener:Dynamic, capture:Bool = false):Void {
		
		dispatcher.removeEventListener (type, listener, capture);
		
	}
	
	public static function dispatchEvent (event:Event):Bool {
		
		return dispatcher.dispatchEvent (event);
		
	}
	
	public static function hasEventListener (type:String):Bool {
		
		return dispatcher.hasEventListener (type);
		
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

			var dynResp:Dynamic = Json.parse(strRes);
			IAP.inventory = new Inventory(dynResp);
			
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