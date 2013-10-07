package org.haxe.extension.iap;


import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.ImageView;
import org.haxe.extension.iap.util.*;
import org.haxe.extension.Extension;
import org.haxe.nme.HaxeObject;


public class InAppPurchase extends Extension {
	
	
	private static HaxeObject callback = null;
	private static IabHelper inAppPurchaseHelper;
	private static String publicKey = "";
	
	
	public static void buy (String productID) {
		
		InAppPurchase.inAppPurchaseHelper.launchPurchaseFlow (Extension.mainActivity, productID, 1001, mPurchaseFinishedListener, "");
		
	}
	
	
	public static String getPublicKey () {
		
		return publicKey;
		
	}
	
	
	public static void initialize (String publicKey, HaxeObject callback) {
		
		Log.i ("IAP", "Initializing billing service");
		
		InAppPurchase.publicKey = publicKey;
		InAppPurchase.callback = callback;
		
		if (InAppPurchase.inAppPurchaseHelper != null) {
			
			InAppPurchase.inAppPurchaseHelper.dispose ();
			
		}
		
		InAppPurchase.inAppPurchaseHelper = new IabHelper (Extension.mainContext, publicKey);
		InAppPurchase.inAppPurchaseHelper.startSetup (new IabHelper.OnIabSetupFinishedListener () {
			
			public void onIabSetupFinished (IabResult result) {
				
				if (result.isSuccess ()) {
					
					Extension.callbackHandler.post (new Runnable () {
						
						@Override public void run () {
							
							InAppPurchase.callback.call ("onStarted", new Object[] { "Success" });
							
						}
						
					});
					
				}
				
			}
			
		});
		
	}
	
	
	@Override public boolean onActivityResult (int requestCode, int resultCode, Intent data) {
		
		if (inAppPurchaseHelper != null) {
			
			return !inAppPurchaseHelper.handleActivityResult (requestCode, resultCode, data);
			
		}
		
		return super.onActivityResult (requestCode, resultCode, data);
		
	}
	
	
	@Override public void onDestroy () {
		
		if (InAppPurchase.inAppPurchaseHelper != null) {
			
			InAppPurchase.inAppPurchaseHelper.dispose ();
			InAppPurchase.inAppPurchaseHelper = null;
			
		}
		
	}
	
	
	public static void setPublicKey (String s) {
		
		publicKey = s;
		
	}
	
	
	static IabHelper.QueryInventoryFinishedListener mReceivedInventoryListener = new IabHelper.QueryInventoryFinishedListener() { 
		
		public void onQueryInventoryFinished (IabResult result, Inventory inventory) {
			
			if (result.isFailure ()) {
				
				// Handle failure
				
			} else {
				
				//InAppPurchase.inAppPurchaseHelper.consumeAsync(inventory.getPurchase(NameOfItem), mConsumeFinishedListener);
				
			}
			
		}
		
	};
	
	
	static IabHelper.OnConsumeFinishedListener mConsumeFinishedListener = new IabHelper.OnConsumeFinishedListener () {
		
		public void onConsumeFinished (Purchase purchase, IabResult result) {
			
			if (result.isSuccess ()) {
				
					
				
			} else {
				
				
				
			}
			
		}
		
	};
	
	
	static IabHelper.OnIabPurchaseFinishedListener mPurchaseFinishedListener = new IabHelper.OnIabPurchaseFinishedListener () {
		
		public void onIabPurchaseFinished (IabResult result, Purchase purchase) {
			
			if (result.isFailure ()) {
				
				 
				
			} else{
				
				
					
			}
			
		}
		
	};
	
	
}