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
		#if ios
			localizedPrice = cast Reflect.field(dynObj, "localizedPrice");
			priceAmountMicros = cast Reflect.field(dynObj, "priceAmountMicros");
			priceCurrencyCode = cast Reflect.field(dynObj, "priceCurrencyCode");
			localizedDescription = cast Reflect.field(dynObj, "localizedDescription");
			localizedTitle = cast Reflect.field(dynObj, "localizedTitle");
		#else
			localizedPrice = cast Reflect.field(dynObj, "price");
			priceAmountMicros = cast Reflect.field(dynObj, "price_amount_micros");
			priceCurrencyCode = cast Reflect.field(dynObj, "price_currency_code");
			localizedDescription = cast Reflect.field(dynObj, "description");
			localizedTitle = cast Reflect.field(dynObj, "title");
		#end
		price = priceAmountMicros / 1000 / 1000;
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
