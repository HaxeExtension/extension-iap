package extension.iap.ios;

import cpp.Lib;
import extension.iap.IAP;
import flash.errors.Error;
import flash.events.Event;
import flash.events.EventDispatcher;
import haxe.Json;

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
 * consume method for iOS, but for consumable items you may want to locally erase the purchase from
 * the Inventory.
 *
 * You may want to check the IAPEvent, Purchase and ProductDetails classes to explore further.
 *
 */

@:allow(extension.iap) class IAP {

	public static var available (get, null):Bool;
	public static var manualTransactionMode (get, set):Bool;

	public static var inventory(default, null):Inventory = null;

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

		if (!initialized) {

			inventory = new Inventory(null);

			set_event_handle (notifyListeners);

			initialized = true;

		}

		purchases_initialize();

	}

	public static function cleanup (publicKey:String = ""):Void {
		if (initialized) {

			purchases_release();

			initialized = false;
		}
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

		purchases_buy (productID);

	}

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

		var productID:String;

		tempProductsData.splice(0, tempProductsData.length);

		if (Std.is(inArg, String))
			purchases_get_data (cast(inArg, String));
		else if (Std.is(inArg, Array))
			purchases_get_data (cast(inArg, Array<Dynamic>).join(","));
		else
			throw new flash.errors.Error("Invalid parameter type: " + Type.typeof(inArg) + ". Valid types are String and Array<String>.");

	}

	/**
	 * Asks the payment queue to restore previously completed purchases.
	 *
	 * Related Events (IAPEvent):
	 * 		PRODUCTS_RESTORED: Fired when the restore process has successfully finished.
	 * 		PRODUCTS_RESTORED_WITH_ERRORS: Fired when the restore process finished with errors.
	 */

	public static function restorePurchases ():Void {

		purchases_restore ();

	}

	/**
	 * Sends a consume intent for a given product.
	 *
	 * @param purchase. The previously purchased product.
	 *
	 * Related Events (IAPEvent):
	 * 		PURCHASE_CONSUME_SUCCESS: Fired when the consume attempt was successful
	 * 		PURCHASE_CONSUME_FAILURE: Fired when the consume attempt failed
	 */

	public static function consume (purchase:Purchase) : Void {

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

	}

	/**
	 * Manually finishes a transaction from the SKPaymentQueue. If <code>manualTransactionMode</code> is false,
	 * this method will no-op.
	 *
	 * @param transactionID Transaction identifier. {@link Purchase#transactionID}
	 * @return True if the transaction existed in the SKPaymentQueue and was successfully finished.
	 */

	public static function finishTransactionManually (transactionID:String):Bool {

		return purchases_finish_transaction (transactionID);

	}

	public static function release ():Void {

		purchases_release ();

	}

	//TODO
	/*public static function displayProductView (productID:String):Void {

	}*/


	// Private Static Methods


	private static function registerHandle ():Void {

		set_event_handle (notifyListeners);

	}


	private static function notifyListeners (inEvent:Dynamic):Void {

		var type = Std.string (Reflect.field (inEvent, "type"));
		var data = Std.string (Reflect.field (inEvent, "data"));

		trace('--------------------------- iap event: ' + type);

		switch (type) {

			case "started":

				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT, data));

			case "success":

				var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_SUCCESS);
				evt.purchase = new Purchase(inEvent);
				evt.productID = evt.purchase.productID;
				inventory.purchaseMap.set(evt.purchase.productID, evt.purchase);

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
				var prod:IAProduct = { productID: Reflect.field (inEvent, "productID"), localizedTitle: Reflect.field (inEvent, "localizedTitle"), localizedDescription: Reflect.field (inEvent, "localizedDescription"), localizedPrice: Reflect.field (inEvent, "localizedPrice"), priceAmountMicros: Reflect.field (inEvent, "priceAmountMicros"), price: Reflect.field(inEvent, "priceAmountMicros")/1000/1000, priceCurrencyCode: Reflect.field (inEvent, "priceCurrencyCode")};
				trace('iOS Product: ' + prod);
				tempProductsData.push( prod );
				inventory.productDetailsMap.set(prod.productID, new ProductDetails(prod));

			case "productDataComplete":

				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE, null, tempProductsData));
				tempProductsData.splice(0, tempProductsData.length);

			case "productDataFailed":

				dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA_FAILED, data));

			default:

		}

	}


	// Getter & Setter Methods


	private static function get_available ():Bool {

		return true;
		// this can bye never seems to return true in testing; disabling for now -- marty
		// return purchases_canbuy ();

	}

	private static function get_manualTransactionMode ():Bool {

		return purchases_get_manualtransactionmode ();

	}

	private static function set_manualTransactionMode (val:Bool):Bool {

		purchases_set_manualtransactionmode (val);

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

}
