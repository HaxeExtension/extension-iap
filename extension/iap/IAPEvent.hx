package extension.iap;


import flash.events.Event;


class IAPEvent extends Event {
	
	
	public static inline var PURCHASE_CANCEL = "purchaseCanceled";
	public static inline var PURCHASE_FAILURE = "purchaseFailed";
	public static inline var PURCHASE_INIT = "init";
	public static inline var PURCHASE_RESTORE = "purchaseRestored";
	public static inline var PURCHASE_SUCCESS = "purchaseSuccess";
	
	public var productID:String;
	
	
	public function new (type:String, productID:String = "") {
		
		super (type);
		
		this.productID = productID;
		
	}
	
	
}