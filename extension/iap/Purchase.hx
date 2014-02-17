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
	
	// iOS Properties
	
	public function new(baseObj:Dynamic) 
	{
		var originalJson:String = "";
		var dynObj:Dynamic = null;
		
		if (Std.is(baseObj, String)) {
			originalJson = cast (baseObj, String);
			dynObj = Json.parse(originalJson);
		} else {
			dynObj = baseObj;
			originalJson = Json.stringify(dynObj);
		}
		//trace("beforeParse: " + originalJson);
		//trace("parsed: " + dynObj);
		
		productID = Reflect.field(dynObj, "productId");
		itemType = Reflect.field(dynObj, "itemType");
		orderId = Reflect.field(dynObj, "orderId");
		packageName = Reflect.field(dynObj, "packageName");
		purchaseTime = Reflect.field(dynObj, "purchaseTime");
		purchaseState = Reflect.field(dynObj, "purchaseState");
		developerPayload = Reflect.field(dynObj, "developerPayload");
		purchaseToken = Reflect.field(dynObj, "purchaseToken");
		signature = Reflect.field(dynObj, "signature");
		
		this.originalJson = originalJson;
	}
	
}