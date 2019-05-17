package extension.iap;

import extension.iap.IAP;

import flash.events.Event;


class IAPEvent extends Event {
	
	
	public static inline var PURCHASE_INIT = "init";
	public static inline var PURCHASE_INIT_FAILED = "initFailed";
	public static inline var PRODUCTS_RESTORED = "purchasesRestored";
	public static inline var PRODUCTS_RESTORED_WITH_ERRORS = "purchasesRestoredWithErrors";
	public static inline var PURCHASE_SUCCESS = "purchaseSuccess";
	public static inline var PURCHASE_FAILURE = "purchaseFailed";
	public static inline var PURCHASE_CANCEL = "purchaseCanceled";
	public static inline var PURCHASE_CONSUME_SUCCESS = "consumeSuccess";
	public static inline var PURCHASE_CONSUME_FAILURE = "consumeFailed";
	public static inline var PURCHASE_PRODUCT_DATA_COMPLETE = "productDataComplete";
	public static inline var PURCHASE_PRODUCT_DATA_FAILED = "productDataFailed";
	public static inline var DOWNLOAD_COMPLETE = "downloadComplete";
	public static inline var DOWNLOAD_START = "downloadStart";
	public static inline var DOWNLOAD_PROGRESS = "downloadProgress";
	
	public var productID:String;
	public var productsData:Array<IAProduct>;
	public var invalidProductIDs:Array<String>;
	
	public var message:String;
	
	public var transactionID:String;
	
	public var downloadPath:String;
	public var downloadProgress:String;
	public var downloadVersion:String;
	
	public var purchase:Purchase;
	
	
	
	public function new (type:String, productID:String = "", ?productsData:Array<IAProduct>, ?invalidProductIDs:Array<String>, ?transactionID:String) {
		
		super (type);
		
		this.productID = productID;
		
		if (productsData != null) this.productsData = productsData;
		if (invalidProductIDs != null) this.invalidProductIDs = invalidProductIDs;
		if (transactionID != null) this.transactionID = transactionID;
	}
	
	
}