package model;
import extension.iap.IAP;
import extension.iap.IAPEvent;
import flash.display.BitmapData;
import com.emibap.core.ScreenUtils;
import haxe.xml.Fast;
import openfl.Assets;
import ui.Store;

typedef ElementDefinition = {
	id:String,
	bmd:BitmapData,
	?buyPrice:Float,
	?upgradePriceMultiplier:Float
}
 
class GameModel
{
	// CallBacks
	public var onStoreDataParsed:Map<String, StoreItemData>->Void;
	public var onStoreDataError:Void->Void;
	
	
	private static var _instance	:GameModel;
	
	public var bgBmd(default, null):BitmapData;
	public var statusBarBgBmd(default, null):BitmapData;
	public var startingGold(default, null):Int;
	public var startingLevel(default, null):Int;
	
	public var data(default, null):Fast;
	public var elementDefinitions(default, null):Map<String, ElementDefinition>;
	public var residentialCommercialSkins(default, null):Array<String>;
	
	public static function getInstance():GameModel {
		if (_instance == null) {
			_instance = new GameModel();
		}
		return _instance;
	}
	
	public function new() 
	{
		this.data = new Fast(Xml.parse(Assets.getText("txt/world.xml")).firstElement());
		
		init();
	}
	
	function init() 
	{
		bgBmd = ScreenUtils.getBitmapData(this.data.node.background.att.img);
		statusBarBgBmd = ScreenUtils.getBitmapData(this.data.node.UI.att.statusBarBgURI);
		
		startingGold = Std.parseInt(this.data.node.startingConditions.att.gold);
		startingLevel = Std.parseInt(this.data.node.startingConditions.att.level);
		residentialCommercialSkins = this.data.node.elements.att.resComSkins.split(",");
		
		elementDefinitions = new Map<String, ElementDefinition>();
		populateElementDefinitions();
		
	}
	
	public function getXmlEl(node:Xml, name:String):Xml {
		var res: Xml;
		for ( el in node.elementsNamed(name) ) {
			res = el;
			break;
		}

		return res;
	}
	
	function populateElementDefinitions():Void {
		var elD:ElementDefinition;
		for ( elt in data.node.elements.elements ) {
			elD = {id:elt.name , bmd: ScreenUtils.getBitmapData(elt.att.img) };
			if (elt.has.buyPrice) elD.buyPrice = Std.parseFloat(elt.att.buyPrice);
			if (elt.has.upgradePriceMultiplier) elD.upgradePriceMultiplier = Std.parseFloat(elt.att.upgradePriceMultiplier);
			elementDefinitions.set(elt.name, elD);
		}
		
	}
	
}