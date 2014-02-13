package ui;
import com.emibap.core.ScreenUtils;
import com.emibap.ui.MessageBox;
import com.emibap.ui.UIUtils;
import extension.iap.IAP;
import extension.iap.IAPEvent;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import haxe.xml.Fast;
import model.GameUserData;
import ui.Store.StoreItemData;
import ui.StoreItemPill;
import model.GameModel;

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
		
		//trace("IAP available: " + IAP.available);
		//if (IAP.available) {
			initializeIAP();
		//} else {
			//getStoreDataFromModel();
		//}
		
		addChild(itemsHolder);
		addChild(descTxt);
		addChild(closeBtn);
	}
	
	private function hideMe(e:MouseEvent):Void 
	{
		MessageBox.hideModal(this);
	}
	
	private function onItemSelected(e:MouseEvent):Void 
	{
		var itm:StoreItemPill = cast e.currentTarget;
		trace(itm.id);
		
		// Offer to buy
		
		if (IAP.available) IAP.purchase(itm.id);
		//if (IAP.available) IAP.purchase("android.test.purchased");
		else {
			testPurchase_NoIAP(itm.id);
		}
	}
	
	function initializeIAP() 
	{
		// Google License key: 
		//TODO: Put in config or anywhere
		#if android
		var licenseKey:String = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv2pAdZ0dPy0sr/75E7U4oSYzDLZ7/Vn8YcfR6SN7R60Ew6chHTzRDWxr2XKjgjs3DixwFgcd5YAEv4zWcQfZSSwrOdjycF/5TUAbbfESWAZgB9UDz0NLl5KXaf+HitTlyshAGq7zpsGA52nsu0B/5JF7Sau27Ul1tzTYBWqiOaOEzjfJJppYxbjjTde/wmsEJ2SjqvoSX0zVM3lxpGGNXkvsPBdK8uT8/WU9w5iD2gW0PNsVbPYP2ceF5Q+mPkCef5XNS+nj5nkFHO3oA2Da4Ep4UELg2iQ7uHN0vFcTTJ3KLovZHWLS6ID72OwzfLtpEO/rzT6nKslDfiWz8oU9jwIDAQAB";
		#else
		var licenseKey:String = "";
		#end
		
		IAP.addEventListener(IAPEvent.PURCHASE_INIT, onPurchaseInit);
		IAP.addEventListener(IAPEvent.PURCHASE_INIT_FAILED, onPurchaseInitFailed);
		
		IAP.addEventListener(IAPEvent.PURCHASE_SUCCESS, onPurchaseSuccess);
		IAP.addEventListener(IAPEvent.PURCHASE_FAILURE, onPurchaseFail);
		IAP.addEventListener(IAPEvent.PURCHASE_CANCEL, onPurchaseCancel);
		
		IAP.addEventListener(IAPEvent.PURCHASE_CONSUME_SUCCESS, onConsumeSuccess);
		IAP.addEventListener(IAPEvent.PURCHASE_CONSUME_FAILURE, onConsumeFail);
		
		IAP.addEventListener(IAPEvent.PRODUCTS_RESTORED, onPurchasesRestored);
		IAP.addEventListener(IAPEvent.PRODUCTS_RESTORED_WITH_ERRORS, onPurchasesRestoredWithErrors);
		IAP.addEventListener(IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE, onStoreDataArrived);
		IAP.addEventListener(IAPEvent.DOWNLOAD_START, onProductDownloadStart);
		IAP.addEventListener(IAPEvent.DOWNLOAD_COMPLETE, onProductDownloadComplete);
		IAP.addEventListener(IAPEvent.DOWNLOAD_PROGRESS, onProductDownloadProgress);
		
		IAP.addEventListener(IAPEvent.PURCHASE_QUERY_INVENTORY_COMPLETE, onQueryInventoryComplete);
		IAP.addEventListener(IAPEvent.PURCHASE_QUERY_INVENTORY_FAILED, onQueryInventoryFailed);
		
		
		IAP.initialize(licenseKey);
		//trace("getManualTransactionMode: " + IAP.manualTransactionMode);
		
		trace("IAP: Available: " + IAP.available);
	}
	
	private function onPurchaseInit(e:IAPEvent):Void 
	{
		trace(e.type);
		getStoreDataFromIAP();
	}
	
	private function onPurchaseInitFailed(e:Event):Void 
	{
		trace(e.type);
		getStoreDataFromModel();
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
	
	
	private function onStoreDataArrived(e:IAPEvent):Void 
	{
		trace("onStoreDataArrived");
		
		
		if (IAP.inventory != null) {
			trace("IAP.inventory: " + IAP.inventory);
			trace("IAP.inventory.productDetailsMap: " + IAP.inventory.productDetailsMap);
			trace("IAP.inventory.purchaseMap: " + IAP.inventory.purchaseMap);
		}
		
		setStoreData(e.productsData);
	}
	
	
	private function onQueryInventoryComplete(e:IAPEvent):Void 
	{
		trace(e.type);
		trace("Products Data: ");
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
		
		trace(".");
		
		if (IAP.inventory != null) {
			trace("IAP.inventory: " + IAP.inventory);
			trace("IAP.inventory.productDetailsMap: " + IAP.inventory.productDetailsMap);
			trace("IAP.inventory.purchaseMap: " + IAP.inventory.purchaseMap);
			
			if (IAP.inventory.purchaseMap.exists("android.test.purchased")) {
				IAP.consume(IAP.inventory.purchaseMap.get("android.test.purchased"));
			}
		}
		
		if (e.productsData.length > 0) {
			setStoreData(e.productsData);
		} else {
			trace("No productsData, calling model");
			getStoreDataFromModel();
			
		}
		
	}
	
	
	private function setStoreData(productsData:Array<IAProduct>):Void {
		
		var model:GameModel = GameModel.getInstance();
		var order:Array<String> = model.data.node.storeItems.att.order.split(",");
		
		
		var map:Map<String, StoreItemData> = new Map<String, StoreItemData>();

		var storeElems:Xml = model.data.node.storeItems.x;
		
		var fastEl:Fast;
		var xmlEl:Xml;
		for (elt in productsData) {
			xmlEl = model.getXmlEl(storeElems, elt.productID);
			
			if (xmlEl != null) {
				fastEl = new Fast(xmlEl);
				map.set(elt.productID, {id:elt.productID, thumb:ScreenUtils.getBitmapData(fastEl.att.thumb), description:elt.localizedTitle + " " + elt.price, reward:(fastEl.has.reward)? Std.parseInt(fastEl.att.reward) : null} );
			}
			
		}
		
		this.data = map;
		var itmPill:StoreItemPill;
		var datum:StoreItemData;
		for (i in 0...order.length) {
			datum = data.get(order[i]);
			itmPill = new StoreItemPill(datum.id, datum.thumb, datum.description);
			itemsHolder.addChild(itmPill);
			
			itmPill.x = i * (ScreenUtils.scaleFloat(5) + itmPill.width);
			itemsHolder.addChild(itmPill);
			
			itmPill.addEventListener(MouseEvent.CLICK, onItemSelected);
		}
		
	}
	
	private function onQueryInventoryFailed(e:IAPEvent):Void
	{
		trace(e.type);
		getStoreDataFromModel();
	}
	
	private function onPurchaseSuccess(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID);
		//var prod:StoreItemData = data.get(e.productID);
		
		//if (prod.reward != null) GameUserData.getInstance().gold += prod.reward;
		
		#if android
		//test
		
		//trace("sending test consume for " + e.purchase + " - payload: " + e.purchase.developerPayload);
		//IAP.consume(e.purchase);
		#else
		onConsumeSuccess(e);
		#end
	}
	
	private function onPurchaseFail(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID + " - message: " + e.message);
	}
	
	private function onPurchaseCancel(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID);
	}
	
	private function onConsumeSuccess(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID);
		
		if (data.exists(e.productID)) {
			var prod:StoreItemData = data.get(e.productID);
			if (prod.reward != null) GameUserData.getInstance().gold += prod.reward;
		}
		
	}
	
	private function onConsumeFail(e:IAPEvent):Void 
	{
		trace(e.type + " - productID: " + e.productID + " - message: " + e.message);
		//var prod:StoreItemData = data.get(e.productID);
		//if (prod.reward != null) GameUserData.getInstance().gold += prod.reward;
		
	}
	
	private function onPurchasesRestored(e:IAPEvent):Void 
	{
		trace(e.type);
	}
	
	private function onPurchasesRestoredWithErrors(e:IAPEvent):Void 
	{
		trace(e.type);
	}
	
	
	
	
	
	
	private function getStoreDataFromIAP() :Void {
		trace("getStoreDataFromIAP");
		
		var orderArr:Array<String> = GameModel.getInstance().data.node.storeItems.att.order.split(",");
		
		#if ios
		IAP.requestProductData (orderArr);
		#elseif android
		IAP.queryInventory (true, orderArr);
		#end
	}
	
	private function getStoreDataFromModel():Void {
		trace("getStoreDataFromModel");
		
		var productsArray:Array<IAProduct> = [];
		
		var model:GameModel = GameModel.getInstance();
		
		//var map:Map<String, StoreItemData> = new Map<String, StoreItemData>();

		//var storeElems:Xml = model.data.node.storeItems.x;
		
		var fastEl:Fast;
		
		for (fastEl in model.data.node.storeItems.elements) {
			
			//fastEl = new Fast(model.getXmlEl(storeElems, elt.productID));
			productsArray.push( { productID: fastEl.att.id, localizedTitle: fastEl.att.title, price: fastEl.att.price } );
			//map.set(fastEl.att.id, {id:fastEl.att.id, thumb:ScreenUtils.getBitmapData(fastEl.att.thumb), description:fastEl.att.title + " " + fastEl.att.price, reward:(fastEl.has.reward)? Std.parseInt(fastEl.att.reward) : null} );
		}
		
		setStoreData(productsArray);
		
	}
	
	function testPurchase_NoIAP(productID:String) 
	{
		trace("PURCHASE WITHOUT IAP - productID: " + productID);
		var prod:StoreItemData = data.get(productID);
		if (prod.reward != null) GameUserData.getInstance().gold += prod.reward;
	}
	
}