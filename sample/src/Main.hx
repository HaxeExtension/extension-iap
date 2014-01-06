package ;

import com.emibap.core.ScreenUtils;
import com.emibap.ui.MessageBox;
import com.emibap.ui.UIUtils;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.Lib;
import model.GameModel;
import model.GameUserData;
import openfl.Assets;
import states.GameState;
import states.State;
import states.TitleState;
import ui.Store;

import flash.text.TextField;

import extension.iap.IAP;
import extension.iap.IAPEvent;

/**
 * ...
 * @author Emiliano Angelini - Emibap
 */

class Main extends Sprite 
{
	var inited:Bool;

	var model:GameModel;
	var gameUserData:GameUserData;
	
	var titleState:TitleState;
	var gameState:GameState;
		
	var currState:State;
	
	/* ENTRY POINT */
	
	function resize(e) 
	{
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init() 
	{
		if (inited) return;
		inited = true;
		// (your code here)
		Lib.current.removeChild(this);
		
		ScreenUtils.setScaleMatrix();
		
		model = GameModel.getInstance();
		
		gameUserData = GameUserData.getInstance();
		gameUserData.init(model);
		
		MessageBox.initialize(Lib.current);
		
		titleState = new TitleState();
		titleState.onStartNewGame = startNewGame;
		titleState.onContinueGame = startNewGameContinued;
		
		gameState = new GameState();
		
		switchState(titleState);
		
		
		
		
	}
	
	function startNewGameContinued() :Void
	{
		switchState(gameState);
	}
	
	function startNewGame() :Void
	{
		gameUserData.clearUserData();
		switchState(gameState);
	}
	
	private function switchState(st:State, removeLast:Bool=true, removeOhters:Bool=false):Void {
		trace("SwitchSTATE st: " + st + " - curr: " + currState);
		if (st != currState) {
			if (currState != null && removeLast) {
				currState.stop();
				if (Lib.current.contains(currState)) Lib.current.removeChild(currState);
			}
			if (!Lib.current.contains(st)) Lib.current.addChild(st);
			currState = st;
			currState.start();
		}
	}
	
	
	/* SETUP */

	public function new() 
	{
		super();	
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	function added(e) 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
		stage.addEventListener(Event.RESIZE, resize);
		#if ios
		haxe.Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}
	
	public static function main() 
	{
		// static entry point
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}
}
