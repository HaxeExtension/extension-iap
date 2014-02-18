package states;
import com.emibap.ui.UIUtils;
import extension.iap.IAP;
import flash.display.Sprite;
import flash.events.Event;
import model.GameModel;
import model.GameUserData;

class TitleState extends State
{

	// Callbacks
	public var onStartNewGame:Void->Void;
	public var onContinueGame:Void->Void;
	
	
	var model:GameModel;
	var userData:GameUserData;
	
	public function new() 
	{
		super();
		
		model = GameModel.getInstance();
		userData = GameUserData.getInstance();
		
		init();
	}
	
	function init() 
	{
		createUI();
	}
	
	
	function createUI() 
	{
		createIAP_UI();
		
		//trace(ScreenUtils.applicationWidth + ", " + ScreenUtils.applicationHeight);
		//MessageBox.showModal("Hola");
		
	}
	
	function createIAP_UI() 
	{
		var startNewBtn:Sprite = UIUtils.createSprBtn("New Game", doStartNewGame);
		var continueBtn:Sprite = UIUtils.createSprBtn("Continue", doContinueGame);
		
		/*
		var restoreBtn:Sprite = UIUtils.createSprBtn("Restore", doRestore);
		var buyRodBtn:Sprite = UIUtils.createSprBtn("BuyRod", doBuyRod);
		var checkRodBtn:Sprite = UIUtils.createSprBtn("CheckRod", doCheckRod);
		
		var buyMagMakBtn:Sprite = UIUtils.createSprBtn("BuyMaginMkp", doBuyMagMk);
		var buySilvShBtn:Sprite = UIUtils.createSprBtn("BuySilverShoes", doBuySilverShoes);
		
		var getRodDataBtn:Sprite = UIUtils.createSprBtn("GetRodData", doGetRodData);
		
		
		buyRodBtn.y = 100;
		
		checkRodBtn.y = 200;
		
		buyMagMakBtn.y = 320;
		buySilvShBtn.y = 420;
		
		getRodDataBtn.y = 520;
		*/
		
		startNewBtn.x = 320;
		
		continueBtn.x = 320;
		continueBtn.y = 100;
		
		addChild(startNewBtn);
		addChild(continueBtn);
		
		//addChild(restoreBtn);
		//addChild(buyRodBtn);
		//addChild(checkRodBtn);
		//addChild(buyMagMakBtn);
		//addChild(buySilvShBtn);
		//addChild(getRodDataBtn);
	}
	
	function doContinueGame(e:Event) 
	{
		if (onStartNewGame != null) onContinueGame();
	}
	
	function doStartNewGame(e:Event) 
	{
		if (onContinueGame != null) onStartNewGame();
	}
	
	/*
	function doGetRodData(e:Event) 
	{
		trace("Pidiendo data de BeautyROD");
		IAP.requestProductData(["BeautyROD","SilverShoes","magMakeupOrb_1"]);
	}
	
	function doBuySilverShoes(e:Event) 
	{
		IAP.purchase("SilverShoes");
	}
	
	function doBuyMagMk(e:Event) 
	{
		IAP.purchase("magMakeupOrb_1");
		IAP.manualTransactionMode = !IAP.manualTransactionMode;
	}
	
	function doCheckRod(e:Event) 
	{
		trace("Comprado y en stock: " + IAP.hasPurchased("BeautyROD"));
		trace("getManualTransactionMode: " + IAP.manualTransactionMode);
	}
	
	function doBuyRod(e:Event) 
	{
		IAP.purchase("BeautyROD");
	}
	
	function doRestore(e:Event) 
	{
		IAP.restorePurchases();
	}
	*/
	
}