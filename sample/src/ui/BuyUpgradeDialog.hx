package ui;
import com.emibap.core.ScreenUtils;
import com.emibap.ui.MessageBox;
import com.emibap.ui.UIUtils;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import model.GameModel;

class BuyUpgradeDialog extends Sprite
{

	// Callbacks
	public var onItemSelected:ElementDefinition->Void;
	
	private static var instance:BuyUpgradeDialog;
	
	private var holder:Sprite;
	
	private var descTxt:TextField;
	private var priceTxt:TextField;
	
	private var storeBtn:BitmapButton;
	private var closeBtn:BitmapButton;
	
	private var items:Map<BitmapButton, ElementDefinition>;
	
	private var halfW:Float;
	
	private static inline var MAX_THUMB_HEIGHT:Float = 100.0;
	private var maxThumbHeight:Float;
	
	public static function getInstance(skinsArr:Array<ElementDefinition> = null, enoughFunds:Bool=true):BuyUpgradeDialog {
		if (instance == null) {
			instance = new BuyUpgradeDialog();
		}
		
		if (skinsArr != null) instance.showProducts(skinsArr, enoughFunds);
		
		return instance;
	}
	public function new() {
		super();
		
		maxThumbHeight = ScreenUtils.scaleFloat(MAX_THUMB_HEIGHT);
		
		items = new Map<BitmapButton, ElementDefinition>();
		
		var bmd:BitmapData = ScreenUtils.getBitmapData("img/msgBG.png");
		this.graphics.beginBitmapFill(bmd);
		this.graphics.drawRect(0, 0, bmd.width, bmd.height);
		this.graphics.endFill();
		halfW = bmd.width / 2;
		
		descTxt = UIUtils.createTextField(this.width*.8, ScreenUtils.scaleFloat(60), 18);
		var fmt:TextFormat = descTxt.defaultTextFormat;
		fmt.align = TextFormatAlign.CENTER;
		descTxt.defaultTextFormat = fmt;
		descTxt.wordWrap = true;
		descTxt.multiline = true;
		descTxt.y = ScreenUtils.scaleFloat(30);
		descTxt.mouseEnabled = false;
		
		
		holder = new Sprite();
		holder.y = descTxt.y + descTxt.height + ScreenUtils.scaleFloat(5);
		
		closeBtn = new BitmapButton(ScreenUtils.getBitmapData("img/store_closeBtn_Normal.png"), ScreenUtils.getBitmapData("img/store_closeBtn_Down.png"));
		closeBtn.x = Math.round(this.width * .935  - closeBtn.width / 2);
		closeBtn.y = ScreenUtils.scaleFloat(4);
		closeBtn.addEventListener(MouseEvent.CLICK, hideMe);
		
		addChild(holder);
		addChild(descTxt);
		addChild(closeBtn);
	}
	
	private function showProducts(skinsArr:Array<ElementDefinition>, enoughFunds:Bool=true) 
	{
		
		var itm:BitmapButton;
		
		var aspRat:Float;
		
		for (i in 0...skinsArr.length) {
			itm = new BitmapButton(skinsArr[i].bmd);
			itm.addEventListener(MouseEvent.CLICK, itemSelected);
			
			items.set(itm, skinsArr[i]);
			
			if (itm.height > maxThumbHeight) {
				aspRat = itm.height / itm.width;
				itm.height = maxThumbHeight;
				itm.width = itm.height * aspRat;
			}
			
			itm.x = i * (itm.width + ScreenUtils.scaleFloat(5));
			
			holder.addChild(itm);
		}
		
		holder.x = Math.round(halfW - holder.width / 2);

		if (enoughFunds) {
			descTxt.text = "Select the product you wish to buy:";
			holder.alpha = 1;
			holder.mouseChildren = holder.mouseEnabled = true;
		} else {
			descTxt.text = "You don't have enough gold to buy. You can buy some at the store";
			holder.alpha = .6;
			holder.mouseChildren = holder.mouseEnabled = false;
		}
		
		
		descTxt.x = halfW - descTxt.width / 2;
		
	}
	
	private function itemSelected(e:MouseEvent):Void 
	{
		if (onItemSelected != null) {
			onItemSelected(items.get(cast e.currentTarget));
			hideMe();
		}
	}
	
	function removeProducts() 
	{
		var itm:BitmapButton;
		var i:Int = holder.numChildren - 1;
		
		while (i > -1) {
			itm = cast holder.getChildAt(i);
			holder.removeChild(itm);
			if (itm.hasEventListener(MouseEvent.CLICK)) itm.removeEventListener(MouseEvent.CLICK, itemSelected);
			itm.destroy();
			i--;
		}
	}
	
	private function hideMe(?e:Event):Void 
	{
		removeProducts();
		
		MessageBox.hideModal(this);
	}
	
}

