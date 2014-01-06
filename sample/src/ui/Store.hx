package ui;
import com.emibap.core.ScreenUtils;
import com.emibap.ui.MessageBox;
import com.emibap.ui.UIUtils;
import extension.iap.IAP;
import extension.iap.IAPEvent;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import model.GameUserData;
import ui.Store.StoreItemData;
import ui.StoreItemPill;

/**
 * ...
 * @author Emiliano Angelini - Emibap
 */

typedef StoreItemData = {
	id			:String,
	thumb		:BitmapData,
	description	:String,
	?reward:Int
}
 
 
class Store extends Sprite
{

	private static var instance:Store;
	
	public static function getInstance() :Store {
		if (instance == null) {
			instance = new Store();
		}
		return instance;
	}
	
	var closeBtn:BitmapButton;
	
	var data:Map<String, StoreItemData>;
	var itemsHolder:Sprite;
	
	public function new() 
	{
		super();
		init();
	}
	
	function init() 
	{
		initializeIAP();
		
		var bmd:BitmapData = ScreenUtils.getBitmapData("img/msgBG.png");
		this.graphics.beginBitmapFill(bmd);
		this.graphics.drawRect(0, 0, bmd.width, bmd.height);
		this.graphics.endFill();
		
		closeBtn = new BitmapButton(ScreenUtils.getBitmapData("img/store_closeBtn_Normal.png"), ScreenUtils.getBitmapData("img/store_closeBtn_Down.png"));
		closeBtn.x = Math.round(this.width * .935  - closeBtn.width / 2);
		closeBtn.y = ScreenUtils.scaleFloat(4);
		closeBtn.addEventListener(MouseEvent.CLICK, hideMe);
		
		var descTxt:TextField = UIUtils.createTextField(this.width*.8, ScreenUtils.scaleFloat(40), 18);
		var fmt:TextFormat = descTxt.defaultTextFormat;
		fmt.align = TextFormatAlign.CENTER;
		descTxt.defaultTextFormat = fmt;
		descTxt.text = "Select the product you wish to buy:";
		
		descTxt.x = this.width / 2 - descTxt.width / 2;
		descTxt.y = ScreenUtils.scaleFloat(30);
		descTxt.mouseEnabled = false;
		itemsHolder = new Sprite();
		
		itemsHolder.x = ScreenUtils.scaleFloat(36);
		itemsHolder.y = ScreenUtils.scaleFloat(66);
		
		addChild(itemsHolder);
		addChild(descTxt);
		addChild(closeBtn);
	}
	
	private function hideMe(e:MouseEvent):Void 
	{
		MessageBox.hideModal(this);
	}
	
	public function setStoreData(data:Map<String, StoreItemData>, order:Array<String>):Void {
		this.data = data;
		var itmPill:StoreItemPill;
		var datum:StoreItemData;
		for (i in 0...order.length) {
			datum = data.get(order[i]);
			itmPill = new StoreItemPill(datum.id, datum.thumb, datum.description);
			itemsHolder.addChild(itmPill);
			
			itmPill.x = i * (ScreenUtils.scaleFloat(5) + itmPill.width);
			trace(itmPill.width);
			itemsHolder.addChild(itmPill);
			
			itmPill.addEventListener(MouseEvent.CLICK, onItemSelected);
		}
		
	}
	
	private function onItemSelected(e:MouseEvent):Void 
	{
		var itm:StoreItemPill = cast e.currentTarget;
		trace(itm.id);
		
		// Offer to buy
		// Temp success
		//onPurchaseSuccess(new IAPEvent("", itm.id));
		
		IAP.purchase(itm.id);
	}
	
	function initializeIAP() 
	{
		IAP.initialize();
		
		IAP.addEventListener(IAPEvent.PURCHASE_CANCEL, onPurchaseCancel);
		IAP.addEventListener(IAPEvent.PURCHASE_FAILURE, onPurchaseFail);
		IAP.addEventListener(IAPEvent.PURCHASE_INIT, onPurchaseInit);
		IAP.addEventListener(IAPEvent.PRODUCTS_RESTORED, onPurchasesRestored);
		IAP.addEventListener(IAPEvent.PRODUCTS_RESTORED_WITH_ERRORS, onPurchasesRestoredWithErrors);
		IAP.addEventListener(IAPEvent.PURCHASE_SUCCESS, onPurchaseSuccess);
		IAP.addEventListener(IAPEvent.PURCHASE_PRODUCT_DATA, onSingleProductData);
		IAP.addEventListener(IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE, onProductsDataComplete);
		IAP.addEventListener(IAPEvent.DOWNLOAD_START, onProductDownloadStart);
		IAP.addEventListener(IAPEvent.DOWNLOAD_COMPLETE, onProductDownloadComplete);
		IAP.addEventListener(IAPEvent.DOWNLOAD_PROGRESS, onProductDownloadProgress);
		
		trace("IAP vailable: " + IAP.available);
		//trace("getManualTransactionMode: " + IAP.manualTransactionMode);
	}
	
	private function onProductDownloadStart(e:IAPEvent):Void 
	{
		trace(e.type + " - " + e.productID + " - TR: " + e.transactionID); 
	}
	
	private function onProductDownloadComplete(e:IAPEvent):Void 
	{
		trace(e.type + " - " + e.productID + " - TR: " + e.transactionID); 
		trace("Path: " + e.downloadPath);
		trace("Version: " + e.downloadVersion);
	}
	
	private function onProductDownloadProgress(e:IAPEvent):Void 
	{
		trace(e.type + " - " + e.productID + " - TR: " + e.transactionID); 
		trace("Path: " + e.downloadPath);
		trace("Version: " + e.downloadVersion);
		trace("Progress: " + e.downloadProgress);
	}
	
	private function onProductsDataComplete(e:IAPEvent):Void 
	{
		trace(e.type);
		
		var pr:IAProduct;
		
		if (e.productsData != null) {
			trace("All products at once: " + e.productsData.length);
			for (i in 0...e.productsData.length) {
				pr = e.productsData[i];
				trace("productID: " + pr.productID);
				trace("localizedTitle: " + pr.localizedTitle);
				trace("localizedDescription: " + pr.localizedDescription);
				trace("price: " + pr.price);
				trace("----");
			}
			
			trace(".");
		}
	}
	
	private function onSingleProductData(e:IAPEvent):Void 
	{
		trace(e.type + " - product data: " + e.productID);
	}
	
	private function onPurchaseSuccess(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID);
		var prod:StoreItemData = data.get(e.productID);
		if (prod.reward != null) GameUserData.getInstance().gold += prod.reward;
		
	}
	
	private function onPurchasesRestored(e:IAPEvent):Void 
	{
		trace(e.type);
	}
	
	private function onPurchasesRestoredWithErrors(e:IAPEvent):Void 
	{
		trace(e.type);
	}
	
	private function onPurchaseInit(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID);
	}
	
	private function onPurchaseFail(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID);
	}
	
	private function onPurchaseCancel(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID);
	}
	
}