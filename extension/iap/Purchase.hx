package extension.iap;
import haxe.Json;

class Purchase
{

	public var productID:String;
	
	// Android Properties
	public var itemType(default, null):String;
	public var orderId(default, null):String;
	public var packageName(default, null):String;
	public var purchaseTime(default, null):Int;
	public var purchaseState(default, null):Int;
	public var developerPayload(default, null):String;
	public var purchaseToken(default, null):String;
	public var acknowledged(default, null):Bool;
	public var signature(default, null):String;
	public var originalJson(default, null):String;
	public var json(default, null):String;
	
	//And only for restore
	public var originalJsonB64:String = "";

	// iOS Properties
	public var transactionID(default, null):String;
	public var transactionDate(default, null):Int;
	public var receipt(default, null):String;

	// Blackberry Properties
	public var date : String;
	public var digital_good : String;
	public var digital_sku : String;
	public var license_key : String;
	public var metadata : String;
	public var purchase_id : String;
	
	public function new(baseObj:Dynamic, ?itemType:String, ?signature:String) 
	{

		if (baseObj==null) {
			return;
		}

		var originalJson:String = "";
		var dynObj:Dynamic = null;
		
		if (Std.isOfType(baseObj, String)) {
			originalJson = cast (baseObj, String);
			dynObj = Json.parse(originalJson);
		}
		 else {
			dynObj = baseObj;
			originalJson = Json.stringify(dynObj);
		}
		
		// Handle both Android and iOS Ids
		productID = Reflect.hasField(dynObj, "productId")? Reflect.field(dynObj, "productId") : Reflect.field(dynObj, "productID");
		
		// itemType = Reflect.field(dynObj, "itemType");
		orderId = Reflect.field(dynObj, "orderId");
		packageName = Reflect.field(dynObj, "packageName");
		purchaseTime = Math.floor(Reflect.field(dynObj, "purchaseTime") * 0.001);
		purchaseState = Reflect.field(dynObj, "purchaseState");
		developerPayload = Reflect.field(dynObj, "developerPayload");
		purchaseToken = Reflect.field(dynObj, "purchaseToken");
		acknowledged = Reflect.field(dynObj, "acknowledged");
		
		this.signature = signature;
		this.itemType = itemType;
		
		transactionID = Reflect.field(dynObj, "transactionID");
		transactionDate = Reflect.field(dynObj, "transactionDate");
		receipt = Reflect.field(dynObj, "receipt");
		
		this.originalJson = originalJson;
	}
	
	public function toString() :String {
		var res:String = "Purchase: { ";
		if (Reflect.fields(this).length > 0) {
			for (fieldLabel in Reflect.fields(this)) {
				res += fieldLabel + ": " + Reflect.field(this, fieldLabel) + ", ";
			}
			res = res.substring(0, res.length - 1);
		}
		
		res += " }";
		return res;
	}
}
