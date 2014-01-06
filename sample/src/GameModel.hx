package ;
import flash.display.BitmapData;
import com.emibap.core.ScreenUtils;
import ui.Store;

/**
 * ...
 * @author Emiliano Angelini - Emibap
 */

 typedef ElementDefinition = {
	bmd	:BitmapData,
	?buyPrice:Float,
	?upgradePriceMultiplier:Float
	
 }
 
class GameModel
{

	public var bgBmd(default, null):BitmapData;
	public var statusBarBgBmd(default, null):BitmapData;
	public var startingGold(default, null):Int;
	public var startingLevel(default, null):Int;
	
	public var data(default, null):Xml;
	public var elementDefinitions(default, null):Map<String, ElementDefinition>;
	public var residentialCommercialSkins(default, null):Array<String>;
	
	public function new(data:Xml) 
	{
		this.data = data.firstElement();
		
		init();
	}
	
	function init() 
	{
		bgBmd = ScreenUtils.getBitmapData(getXmlEl(this.data, "background").get("img"));
		statusBarBgBmd = ScreenUtils.getBitmapData(getXmlEl(this.data, "UI").get("statusBarBgURI"));
		
		startingGold = Std.parseInt(getXmlEl(this.data, "startingConditions").get("gold"));
		startingLevel = Std.parseInt(getXmlEl(this.data, "startingConditions").get("level"));
		residentialCommercialSkins = getXmlEl(this.data, "elements").get("resComSkins").split(",");
		
		elementDefinitions = new Map<String, ElementDefinition>();
		populateElementDefinitions();
		
		getStoreData();
	}
	
	function getStoreData() 
	{
		trace("getStoreData");
		var store:Store = Store.getInstance();
		
		var arr:Array<StoreItemData> = [];

		var elmDs:Array<String> = getXmlEl(this.data, "storeItems").get("ids").split(",");
		for (i in 0...elmDs.length) {
			arr.push( {id:"", thumb: ScreenUtils.getBitmapData(elmDs[i]), description:"test"} );
		}
		
		store.setStoreData(arr);
	}
	
	public function getXmlEl(node:Xml, name:String):Xml {
		var res: Xml;
		for ( el in node.elementsNamed(name) ) {
			res = el;
			break;
		}
        // iterate all elements with a nodeName "user"
		return res;
		
	}
	
	function populateElementDefinitions():Void {
		var elD:ElementDefinition;
		for ( elt in getXmlEl(data, "elements").elements() ) {
			elD = { bmd: ScreenUtils.getBitmapData(elt.get("img")) };
			if (elt.exists("buyPrice")) elD.buyPrice = Std.parseFloat(elt.get("buyPrice"));
			if (elt.exists("upgradePriceMultiplier")) elD.upgradePriceMultiplier = Std.parseFloat(elt.get("upgradePriceMultiplier"));
			elementDefinitions.set(elt.nodeName, elD);
		}
		
	}
	
}