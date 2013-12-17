package extension.iap;


import flash.events.Event;


class IAPEvent extends Event {
	
	
	public static inline var PURCHASE_CANCEL = "purchaseCanceled";
	public static inline var PURCHASE_FAILURE = "purchaseFailed";
	public static inline var PURCHASE_INIT = "init";
	public static inline var PURCHASE_RESTORE = "purchaseRestored";
	public static inline var PURCHASE_SUCCESS = "purchaseSuccess";
	public static inline var PURCHASE_PRODUCT_DATA = "productDataArrived";
	public static inline var PURCHASE_PRODUCT_DATA_COMPLETE = "productDataComplete";
	public static inline var PURCHASE_PRODUCT_DATA_COMPLETE_WITH_ERRORS = "productDataCompleteWithErrors";
	
	public var productID:String;
	public var localizedTitle:String;
	public var localizedDescription:String;
	public var price:String;
	
	public var message:String;
	
	
	
	public function new (type:String, productID:String = "", ?localizedTitle:String, ?localizedDescription:String, ?price:String, ?message:String) {
		
		super (type);
		
		this.productID = productID;
		
		if (localizedTitle != null) this.localizedTitle = localizedTitle;
		if (localizedDescription != null) this.localizedDescription = localizedDescription;
		if (price != null) this.price = price;
		if (message != null) this.message = message;
		
	}
	
	
}