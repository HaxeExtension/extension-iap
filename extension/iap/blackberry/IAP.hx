package extension.iap.blackberry;

import extension.iap.IAP;
import flash.errors.Error;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.Lib;
import haxe.Json;
import haxe.Timer;

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

		purchases_initialize();
		var poller = new Timer(100);
		poller.run = purchase_poll_event;

		//dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT_FAILED, null));

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
	public static function consume (purchase:Purchase):Void {

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

	// Getter & Setter Methods

	private static function get_available ():Bool {

		return false;

	}

	private static function get_manualTransactionMode ():Bool {

		return false;

	}

	private static function set_manualTransactionMode (val:Bool):Bool {

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
	private static var purchase_poll_event = Lib.load ("iap", "iap_poll_event", 0);

}
