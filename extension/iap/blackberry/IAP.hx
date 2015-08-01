package extension.iap.blackberry;

import cpp.vm.Thread;
import extension.iap.IAP;
import extension.iap.IAPEvent;
import flash.errors.Error;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.Lib;
import haxe.Json;
import haxe.Timer;

private enum EventType {
	None;
	Purchase;
	RequestProductData;
	QueryInventory;
}

@:allow(extension.iap) class IAP {

	private static var dispatcher = new EventDispatcher ();
	private static var initialized : Bool = false;
	private static var waitingEvent : EventType = None;
	public static var available (get, null):Bool;
	public static var inventory(default, null):Inventory = null;

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
	public static function initialize (publicKey:String = "", localOnly : Bool = false):Void {

		if (!initialized) {

			inventory = new Inventory(null);

			purchases_initialize(localOnly);
			set_event_handle(notifyListeners);

			initialized = true;

			dispatchEvent(new IAPEvent (IAPEvent.PURCHASE_INIT));

		}

	}

	static function pollEvent() {

		purchases_poll_event();

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
	public static function purchase (productID:String, devPayload:String = "") : Void {

		waitingEvent = Purchase;
		purchases_buy(productID);
		while (waitingEvent!=None) {
			pollEvent();
		}

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

		waitingEvent = RequestProductData;
		purchases_get_data(inArg);
		while (waitingEvent!=None) {
			pollEvent();
		}

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

		waitingEvent = QueryInventory;
		purchases_query_inventory();
		while (waitingEvent!=None) {
			pollEvent();
		}

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

	private static function notifyListeners (inEvent:Dynamic):Void {

		var type = Std.string (Reflect.field (inEvent, "type"));
		var data = Std.string (Reflect.field (inEvent, "data"));

		switch (type) {
			case "purchase_sucess": {
				var evt = new IAPEvent(IAPEvent.PURCHASE_SUCCESS);
				evt.purchase = new Purchase(inEvent);
				evt.productID = evt.purchase.productID;
				inventory.purchaseMap.set(evt.purchase.productID, evt.purchase);
				dispatchEvent(evt);
			}
			case "failure":	{
				var evt = switch (waitingEvent) {
					case Purchase:				new IAPEvent(IAPEvent.PURCHASE_FAILURE);
					case RequestProductData:	new IAPEvent(IAPEvent.PURCHASE_PRODUCT_DATA_FAILED);
					case QueryInventory:		new IAPEvent(IAPEvent.PURCHASE_QUERY_INVENTORY_FAILED);
					case None:					null;	// Shouldnt ever happen
				}
				if (evt!=null) {
					evt.message = data;
					dispatchEvent(evt);
				}
			}
			case "product_data": {
				var evt = new IAPEvent(IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE);
				var details : IAProduct = {
					productID : Reflect.field(inEvent, "productID"),
					localizedPrice : Reflect.field(inEvent, "localizedPrice")
				};
				evt.productsData = [details];
				inventory.productDetailsMap.set(details.productID, new ProductDetails(details));
				dispatchEvent(evt);
			}
			case "inventory_sucess": {

				// Reset inventory purchaseMap
				var keys = [for (k in inventory.purchaseMap.keys()) k];
				for (k in keys) {
					inventory.purchaseMap.remove(k);
				}

				var evt = new IAPEvent(IAPEvent.PURCHASE_QUERY_INVENTORY_COMPLETE);
				evt.productsData = [];
				var dynInventory : Array<Dynamic> = Reflect.field(inEvent, "data");
				for (entry in dynInventory) {
					var purchase = new Purchase(null);
					purchase.date = Reflect.field(entry, "date");
					purchase.digital_good = Reflect.field(entry, "digital_good");
					purchase.digital_sku = Reflect.field(entry, "digital_sku");
					purchase.license_key = Reflect.field(entry, "license_key");
					purchase.metadata = Reflect.field(entry, "metadata");
					purchase.productID = purchase.purchase_id = Reflect.field(entry, "purchase_id");
					inventory.purchaseMap.set(purchase.purchase_id, purchase);
				}

			}
			default: {
				trace("N/A");
			}
		}

		waitingEvent = None;

	}

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
	private static var purchases_buy = Lib.load ("iap", "iap_buy", 1);
	private static var purchases_get_data = Lib.load ("iap", "iap_get_data", 1);
	private static var purchases_initialize = Lib.load ("iap", "iap_initialize", 1);
	private static var purchases_poll_event = Lib.load ("iap", "iap_poll_event", 0);
	private static var purchases_query_inventory = Lib.load ("iap", "iap_query_inventory", 0);
	private static var set_event_handle = Lib.load ("iap", "iap_set_event_handle", 1);

}
