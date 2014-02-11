package extension.iap;

/**
 * ...
 * @author emibap - Emiliano Angelini
 */
class ProductDetails
{
	
	public var productID(default, null): String;
    public var localizedTitle(default, null): String;
    public var localizedDescription(default, null): String;
    public var price(default, null): String;
    public var localizedPrice(default, null): String;
	public var type(default, null): String;		//(android)
	
	public function new(dynObj:Dynamic) 
	{
		productID = cast Reflect.field(dynObj, "productId");
		type = cast Reflect.field(dynObj, "type");
		localizedPrice = price = cast Reflect.field(dynObj, "price");
		localizedTitle = cast Reflect.field(dynObj, "title");
		localizedDescription = cast Reflect.field(dynObj, "description");
	}
	
}