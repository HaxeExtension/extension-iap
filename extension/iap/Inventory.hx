package extension.iap;

/**
 * Represents a block of information about in-app items.
 * An Inventory is returned by such methods as {@link IAP#queryInventory}.
 */

class Inventory
{

	public var productDetailsMap(default, null): Map<String, ProductDetails>;
	public var purchaseMap(default, null): Map<String, Purchase>;
	
	public function new(?dynObj:Dynamic) 
	{
		productDetailsMap = new Map();
		purchaseMap = new Map();
		
		if (dynObj != null) {
			
			var dynDescriptions:Array<Dynamic> = Reflect.field(dynObj, "descriptions");
			if (dynDescriptions != null) {
				
				for (dynItm in dynDescriptions) {
					productDetailsMap.set(cast Reflect.field(dynItm, "key"), new ProductDetails(Reflect.field(dynItm, "value")));
				}
				
			}
			
			var dynPurchases:Array<Dynamic> = Reflect.field(dynObj, "purchases");
			if (dynPurchases != null) {
				
				for (dynItm in dynPurchases) {
					var p = new Purchase(Reflect.field(dynItm, "value"), Reflect.field(dynItm, "itemType"), Reflect.field(dynItm, "signature"));
					purchaseMap.set(cast Reflect.field(dynItm, "key"), p);
				}
				
			}
			
		}

	}
	
	/** Returns the listing details for an in-app product. */
	public function getProductDetails(productId:String) :ProductDetails {
		return productDetailsMap.get(productId);
	}
	
	/** Returns purchase information for a given product, or null if there is no purchase. */
    public function getPurchase(productId:String) :Purchase {
        return purchaseMap.get(productId);
    }

    /** Returns whether or not there exists a purchase of the given product. */
    public function hasPurchase(productId:String) :Bool {
        return purchaseMap.exists(productId);
    }

    /** Return whether or not details about the given product are available. */
    public function hasDetails(productId:String) :Bool {
        return productDetailsMap.exists(productId);
    }

    /**
     * Erase a purchase (locally) from the inventory, given its product ID. This just
     * modifies the Inventory object locally and has no effect on the server! This is
     * useful when you have an existing Inventory object which you know to be up to date,
     * and you have just consumed an item successfully, which means that erasing its
     * purchase data from the Inventory you already have is quicker than querying for
     * a new Inventory.
     */
    public function erasePurchase(productId:String) :Void {
		
        if (purchaseMap.exists(productId)) purchaseMap.remove(productId);
    }
	
}
