package extension.iap;


import flash.events.Event;


class IAPEvent extends Event {
	
	
	public static inline var PURCHASE_CANCELED = "purchaseCanceled";
	public static inline var PURCHASE_FAILED = "purchaseFailed";
	public static inline var PURCHASE_READY = "purchaseReady";
	public static inline var PURCHASE_RESTORED = "purchaseRestored";
	public static inline var PURCHASE_SUCCESS = "purchaseSuccess";
	
	public var productID:String;
	
	
	public function new (type:String, productID:String = "") {
		
		super (type);
		
		this.productID = productID;
		
	}
	
	
}