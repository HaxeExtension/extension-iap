package ui;
import com.emibap.core.ScreenUtils;
import com.emibap.ui.UIUtils;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import model.GameModel;
import model.GameUserData;
import ui.BitmapButton;

/**
 * ...
 * @author Emiliano Angelini - Emibap
 */
class StatusBar extends Sprite
{

	//callBacks
	public var onStoreSelected:Void->Void;
	
	var goldTxt:TextField;
	var levelTxt:TextField;
	
	var model:GameModel;
	var userData:GameUserData;
	
	var storeBtn	:BitmapButton;
	
	public function new(model:GameModel, data:Dynamic = null) 
	{
		super();
		this.model = model;
		userData = GameUserData.getInstance();
		init();
		update();
	}
	
	public function update(e:Event = null) 
	{
		goldTxt.text = Std.string(userData.gold);
		levelTxt.text = Std.string(userData.level);
	}
	
	function init() 
	{
		this.graphics.beginBitmapFill(model.statusBarBgBmd);
		this.graphics.drawRect(0, 0, model.statusBarBgBmd.width, model.statusBarBgBmd.height);
		this.graphics.endFill();
		
		
		goldTxt = UIUtils.createTextField(80, 26, 20);
		goldTxt.x = ScreenUtils.scaleInt(46);
		goldTxt.y = ScreenUtils.scaleInt(5);
		goldTxt.mouseEnabled = false;
		
		addChild(goldTxt);	
		
		levelTxt = UIUtils.createTextField(14, 26, 20);
		levelTxt.x = ScreenUtils.scaleInt(178);
		levelTxt.y = ScreenUtils.scaleInt(5);
		levelTxt.mouseEnabled = false;
		
		userData.addEventListener(GameUserData.EVT_DATA_UPDATED, update);
		
		addChild(levelTxt);
		
		storeBtn = new BitmapButton(ScreenUtils.getBitmapData("img/Btn_Shop_Normal.png"), ScreenUtils.getBitmapData("img/Btn_Shop_Down.png"));
		storeBtn.x = model.statusBarBgBmd.width;
		storeBtn.addEventListener(MouseEvent.CLICK, storeSelected);
		
		addChild(storeBtn);
		
		
	}
	
	private function storeSelected(e:MouseEvent):Void 
	{
		trace("StoreSelected");
		if (onStoreSelected != null) onStoreSelected();
	}
	
}