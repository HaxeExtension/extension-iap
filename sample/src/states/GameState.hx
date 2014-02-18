package states;
import com.emibap.core.ScreenUtils;
import com.emibap.ui.MessageBox;
import model.GameModel;
import model.GameUserData;
import ui.BuyUpgradeDialog;
import ui.Store;
import ui.StatusBar;

class GameState extends State
{

	var model:GameModel;
	var userData:GameUserData;
	
	
	var world:WorldMap;
	var statusBar:StatusBar;
	
	public function new() 
	{
		super();
		
		model = GameModel.getInstance();
		userData = GameUserData.getInstance();
		
		init();
	}
	
	function init() 
	{
		
	}
	
	public override function start() :Void {
		world = new WorldMap(model);
		world.onElementSelected = presentElementOptions;
		
		statusBar = new StatusBar(model);
		statusBar.x = ScreenUtils.applicationWidth - statusBar.width;
		statusBar.onStoreSelected = showStore;
		
		BuyUpgradeDialog.getInstance().onItemSelected = buyUpgradeElement;
		
		addChild(world);
		addChild(statusBar);
	}
	
	function presentElementOptions(wel:MapElement) :Void
	{
		
		var arr:Array<ElementDefinition> = [];
		var def:ElementDefinition;// = model.elementDefinitions.get(skName);
		
		if (wel.type != "res_com") {
			var skId:String = wel.id + "_" + Std.string(wel.level);
			def = model.elementDefinitions.get(skId);
			arr.push( def );
		}
		else {
			//skName =  model.residentialCommercialSkins[Math.round(Math.random() * 2)];
			def = model.elementDefinitions.get(model.residentialCommercialSkins[0]);
			for (i in 0...model.residentialCommercialSkins.length) {
				arr.push( model.elementDefinitions.get(model.residentialCommercialSkins[i]) );
			}
		}
		
		MessageBox.showCustomModal(BuyUpgradeDialog.getInstance(arr, (def.buyPrice <= userData.gold)));
		
		/*
		// Buy??
		if (wel.empty) {
			//if (wel.id == "court") {
				
			//}
			trace("Price: " + def.buyPrice);
			if (userData.gold >= def.buyPrice) {
				buyElement(wel, skName);
				
				userData.gold -= def.buyPrice;
			}
			
		} else {
			upgradeElement(wel);
		}*/
		
			
	}
	
	function upgradeElement(wel:MapElement) 
	{
		trace("Upgrade " + wel.id);
	}
	
	function buyUpgradeElement(elDef:ElementDefinition) 
	{
		var wel:MapElement = world.lastSelectedElement;
		
		trace("Buy " + wel.id);
		
		wel.skin = elDef.bmd;
		wel.skinId = elDef.id;
		wel.empty = false;
		
		userData.gold -= elDef.buyPrice;
		
		userData.persistElement(wel);
		
		userData.save();
	}
	
	function showStore() 
	{
		MessageBox.showCustomModal(Store.getInstance());
	}
	
}