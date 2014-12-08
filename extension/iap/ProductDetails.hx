package extension.iap;

class ProductDetails
{
	
	public var productID(default, null): String;
    public var localizedTitle(default, null): String;
    public var localizedDescription(default, null): String;
    public var price(default, null): Float;
    public var localizedPrice(default, null): String;
	public var priceCurrencyCode(default,null):String;
	public var priceAmountMicros(default,null):Float;
	public var type(default, null): String;		//(android)
	
	public function new(dynObj:Dynamic) 
	{
		// Handle both Android and iOS Ids
		productID = Reflect.hasField(dynObj, "productId")? Reflect.field(dynObj, "productId") : Reflect.field(dynObj, "productID");
		type = cast Reflect.field(dynObj, "type");
		localizedPrice = cast Reflect.field(dynObj, "price");
		priceAmountMicros = cast Reflect.field(dynObj, "price_amount_micros");
		price = priceAmountMicros / 1000 / 1000;
		priceCurrencyCode = cast Reflect.field(dynObj, "price_currency_code");
		localizedTitle = cast Reflect.field(dynObj, "title");
		#if ios
			localizedDescription = cast Reflect.field(dynObj, "localizedDescription");
		#else
			localizedDescription = cast Reflect.field(dynObj, "description");
		#end
	}
	
	public function toString() :String {
		var res:String = "ProductDetails: { ";
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