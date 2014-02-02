package org.haxe.extension.iap;

import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

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
import org.haxe.lime.HaxeObject;


import org.json.JSONException;

public class InAppPurchase extends Extension {
	
	
	private static HaxeObject callback = null;
	private static IabHelper inAppPurchaseHelper;
	private static String publicKey = "";
	
	
	public static void buy (String productID) {
		
		InAppPurchase.inAppPurchaseHelper.launchPurchaseFlow (Extension.mainActivity, productID, 1001, mPurchaseFinishedListener, "");
		
	}
	
	public static void consume (String purchaseJson) {
		
		try {
			Purchase purchase = new Purchase(null, purchaseJson, null);
			InAppPurchase.inAppPurchaseHelper.consumeAsync(purchase, mConsumeFinishedListener);
		} 
		catch (JSONException e) {
			InAppPurchase.callback.call ("onQueryInventoryComplete", new Object[] { "Failure" });
		}
		
	}
	
	public static void queryInventory (boolean querySkuDetails, String[] moreSkusArr) {
		List<String> moreSkus = Arrays.asList(moreSkusArr); 
		InAppPurchase.inAppPurchaseHelper.queryInventoryAsync(querySkuDetails, moreSkus, mGotInventoryListener);
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
			
			public void onIabSetupFinished (final IabResult result) {
				
				if (result.isSuccess ()) {
					
					Extension.callbackHandler.post (new Runnable () {
						
						@Override public void run () {
							
							InAppPurchase.callback.call ("onStarted", new Object[] { "Success" });
							
						}
						
					});
					
				} else {
					Extension.callbackHandler.post (new Runnable () {
						
						@Override public void run () {
							
							InAppPurchase.callback.call ("onStarted", new Object[] { "Failure" });
							
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
	
	
	static IabHelper.QueryInventoryFinishedListener mGotInventoryListener = new IabHelper.QueryInventoryFinishedListener() {
	   
		public void onQueryInventoryFinished(final IabResult result, final Inventory inventory) {

		  if (result.isFailure()) {
			// handle error here
			Extension.callbackHandler.post (new Runnable ()
			{
				@Override public void run ()
				{
					
					InAppPurchase.callback.call ("onQueryInventoryComplete", new Object[] { "Failure" });
					
					
				}	
			});
		  }
		  else {
			
			Extension.callbackHandler.post (new Runnable ()
			{
				@Override public void run ()
				{
					/*
					// Testing data injection
					String purchaseJson = "{\"orderId\": \"testOrderId\", \"packageName\": \"testpackageName\", \"productId\": \"testproductId\", \"purchaseTime\": 1000, \"purchaseState\": 1, \"developerPayload\": \"testdeveloperPayload\", \"purchaseToken\": \"testpurchaseToken\" }";
					
					Purchase purchase = null;
					
					try {
						purchase = new Purchase("inapp", purchaseJson, "firmaElEmi");
					} 
					catch (JSONException e) {
						InAppPurchase.callback.call ("onQueryInventoryComplete", new Object[] { "Failure" });
					}
					
					if (purchase != null) {
						IabResult result = new IabResult(IabHelper.BILLING_RESPONSE_RESULT_OK, "Mensaje del Emi");
						
						//test failedPurchase
						//InAppPurchase.callback.call ("onFailedPurchase", new Object[] { ("{\"result\":" + result.toJsonString() + ", \"product\":" + purchase.getOriginalJson() + "}") });
						
						//test purchase
						InAppPurchase.callback.call ("onPurchase", new Object[] { purchase.getOriginalJson() });
						
						//test failedConsume
						//InAppPurchase.callback.call ("onFailedConsume", new Object[] { ("{\"result\":" + result.toJsonString() + ", \"product\":" + purchase.getOriginalJson() + "}") });
						
						//test consume
						//InAppPurchase.callback.call ("onConsume", new Object[] { purchase.getOriginalJson() });
					}
					*/

					
					InAppPurchase.callback.call ("onQueryInventoryComplete", new Object[] { inventory.toJsonString() });
					
				}	
			});
		  }
	   }
	   
	};
	
	
	static IabHelper.OnIabPurchaseFinishedListener mPurchaseFinishedListener = new IabHelper.OnIabPurchaseFinishedListener () {
		
		public void onIabPurchaseFinished (final IabResult result, final Purchase purchase)
		{
			
			if (result.isFailure ()) 
			{
				
				Extension.callbackHandler.post (new Runnable ()
				{
					@Override public void run () 
					{
						InAppPurchase.callback.call ("onFailedPurchase", new Object[] { ("{\"result\":" + result.toJsonString() + ", \"product\":" + purchase.getOriginalJson() + "}") });
					}
				});
			} 
			else
			{
				Extension.callbackHandler.post (new Runnable ()
				{
					@Override public void run ()
					{
						InAppPurchase.callback.call ("onPurchase", new Object[] { purchase.getOriginalJson() });
					}	
				});
			}
			
		}
		
	};
	
	
	static IabHelper.OnConsumeFinishedListener mConsumeFinishedListener = new IabHelper.OnConsumeFinishedListener () {
		
		public void onConsumeFinished (final Purchase purchase, final IabResult result) {
			
			if (result.isFailure ()) 
			{
				
				Extension.callbackHandler.post (new Runnable ()
				{
					@Override public void run () 
					{
						InAppPurchase.callback.call ("onFailedConsume", new Object[] { ("{\"result\":" + result.toJsonString() + ", \"product\":" + purchase.getOriginalJson() + "}") });
					}
				});
			} 
			else
			{
				Extension.callbackHandler.post (new Runnable ()
				{
					@Override public void run ()
					{
						InAppPurchase.callback.call ("onConsume", new Object[] { purchase.getOriginalJson() });
					}	
				});
			}
			
		}
		
	};
	
	
	
	
}