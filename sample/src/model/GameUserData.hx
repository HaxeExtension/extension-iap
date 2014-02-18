package model;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.SharedObject;
import flash.net.SharedObjectFlushStatus;

import flash.errors.Error;

class GameUserData extends EventDispatcher
{
	static public var _instance:GameUserData;
	
	static public inline var EVT_DATA_CLEARED:String = "dataCleared";
	static public inline var EVT_DATA_UPDATED:String = "dataUpdated";
	
	public var data(get, null):Dynamic;
	public var worldElements(default, null):Map<String, MapElement>;
	public var gold(get, set):Float;
	public var level(get, set):Int;
	
	private var _so:SharedObject;
	
	private var model:GameModel;
	
	static public function getInstance():GameUserData {
		if (_instance == null) {
			_instance = new GameUserData();
		}
		return _instance;
	}
	
	public function new() 
	{
		super();
	}
	
	public function init(dataModel:GameModel):Void {
		model = dataModel;
		_so = SharedObject.getLocal("IAP_Sample_SO");
		
		//clearUserData();
		createUserData();
		
	}
	
	private function createUserData() :Void
	{
		
		if (worldElements == null) setupWorldElements();
		try {
			
			if (_so.data.worldElements == null) {
				trace("Existing UserData");
				_so.data.worldElements = [];
				_so.data.gold = model.startingGold;
				_so.data.level = model.startingLevel;
			} else {
			trace("New UserData");
				populateWorldElementsUserData();
			}
			
			trace(_so.data);
			
			_so.flush();
		
		} catch (e:Error) {
			trace(e);
		}	
		
	}
	
	function populateWorldElementsUserData() 
	{
		var el:MapElement;
		var dynEl:Dynamic;
		for (i in 0..._so.data.worldElements.length) {
			dynEl = _so.data.worldElements[i];
			el = worldElements.get(dynEl.id);
			
			el.empty = dynEl.empty;
			el.level = dynEl.level;
			if (dynEl.skinId != null) {
				el.skinId = dynEl.skinId;
				el.skin = model.elementDefinitions.get(el.skinId).bmd;
			}
		}
	}
	
	public function clearUserData():Void {
		//_so.flush();
		trace("cleared");
		
		_so.data.worldElements = worldElements = null;
		_so.clear();

		createUserData();
		
		_so.flush();
		
		dispatchEvent(new Event(EVT_DATA_CLEARED));
	}
	
	function setupWorldElements():Void {
		
		worldElements = new Map<String, MapElement>();
		
		var skId:String = "";
		
		var wel:MapElement;
		for ( elt in model.data.node.map.elements ) {
			wel = new MapElement(elt.att.id, elt.att.type);
			wel.x = Std.parseFloat(elt.att.x);
			wel.y = Std.parseFloat(elt.att.y);
			
			if (elt.has.defSkin) {
				skId = elt.att.defSkin;
				wel.empty = false;
			} else {
				skId = (wel.type == "gov")? "baseLarge" : "base";
			}
			
			wel.skin = model.elementDefinitions.get(skId).bmd;
			
			
			worldElements.set(elt.att.id, wel);
		}
	}
	
	public function persistElement(elem:MapElement):Void {
		
		var i:Int = 0;
		var tempArr:Array<Dynamic> = _so.data.worldElements;
		
		while (i < tempArr.length && tempArr[i].id != elem.id) { i++; }
		
		var tempDyn:Dynamic;
		
		if (i < tempArr.length) {
			tempDyn = tempArr[i];
			
			tempDyn.skinId = elem.skinId;
			tempDyn.empty = elem.empty;
			tempDyn.level = elem.level;
		} else {
			tempDyn = { };
			tempDyn.id = elem.id;
			tempDyn.type = elem.type;
			tempDyn.skinId = elem.skinId;
			tempDyn.empty = elem.empty;
			tempDyn.level = elem.level;
			
			tempArr.push(tempDyn);
		}
		
		
	}
	
	function persistWorldElements() 
	{
		var tempArr:Array<Dynamic> = [];
		var tempDyn:Dynamic;
		
		for (elem in worldElements.iterator()) {
			tempDyn = { };
			tempDyn.id = elem.id;
			tempDyn.type = elem.type;
			tempDyn.skinId = elem.skinId;
			tempDyn.empty = elem.empty;
			tempDyn.level = elem.level;
			
			tempArr.push(tempDyn);
		}
		
		_so.data.worldElements = tempArr;

	}
	
	// Getter/Setter Methods
	
	private function get_data():Dynamic 
	{
		return _so.data;
	}
	
	private function get_gold():Float {
		return (_so.data.gold);
	}
	private function set_gold(val:Float):Float {
		_so.data.gold = val;
		_so.flush();
		dispatchEvent(new Event(EVT_DATA_UPDATED));
		return val;
	}
	
	private function get_level():Int {
		return (_so.data.level);
	}
	private function set_level(val:Int):Int {
		_so.data.level = val;
		_so.flush();
		return val;
	}
	
	
	public function save():Void {
		
		//persistWorldElements();
		
		_so.flush();
	}
	
	
	
}