package extension.iap;

import extension.iap.IAP;

import flash.events.Event;


class IAPEvent extends Event {
	
	
	public static inline var PURCHASE_CANCEL = "purchaseCanceled";
	public static inline var PURCHASE_FAILURE = "purchaseFailed";
	public static inline var PURCHASE_INIT = "init";
	public static inline var PURCHASE_RESTORE = "purchaseRestored";
	public static inline var PURCHASE_SUCCESS = "purchaseSuccess";
	public static inline var PURCHASE_PRODUCT_DATA = "productDataArrived";
	public static inline var PURCHASE_PRODUCT_DATA_COMPLETE = "productDataComplete";
	
	public var productID:String;
	public var productsData:Array<IAProduct>;
	public var invalidProductIDs:Array<String>;
	
	public var message:String;
	
	
	
	public function new (type:String, productID:String = "", ?productsData:Array<IAProduct>, ?invalidProductIDs:Array<String>, ?message:String) {
		
		super (type);
		
		this.productID = productID;
		
		if (productsData != null) this.productsData = productsData;
		if (invalidProductIDs != null) this.invalidProductIDs = invalidProductIDs;	
	}
	
	
}