package extension.iap;
import haxe.Json;

class Purchase
{

	public var productID(default, null):String;
	
	// Android Properties
	public var itemType(default, null):String;
	public var orderId(default, null):String;
	public var packageName(default, null):String;
	public var purchaseTime(default, null):Int;
	public var purchaseState(default, null):Int;
	public var developerPayload(default, null):String;
	public var purchaseToken(default, null):String;
	public var signature(default, null):String;
	public var originalJson(default, null):String;
	public var json(default, null):String;

	// iOS Properties
	public var transactionID(default, null):String;
	public var transactionDate(default, null):Int;
	
	public function new(baseObj:Dynamic, ?itemType:String, ?signature:String) 
	{
		var originalJson:String = "";
		var dynObj:Dynamic = null;
		
		if (Std.is(baseObj, String)) {
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
		purchaseTime = Reflect.field(dynObj, "purchaseTime");
		purchaseState = Reflect.field(dynObj, "purchaseState");
		developerPayload = Reflect.field(dynObj, "developerPayload");
		purchaseToken = Reflect.field(dynObj, "purchaseToken");
		
		this.signature = signature;
		this.itemType = itemType;
		
		transactionID = Reflect.field(dynObj, "transactionID");
		transactionDate = Reflect.field(dynObj, "transactionDate");
		
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
