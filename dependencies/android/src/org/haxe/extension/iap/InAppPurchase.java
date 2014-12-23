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
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

public class InAppPurchase extends Extension {
	
	
	private static HaxeObject callback = null;
	private static IabHelper inAppPurchaseHelper;
	private static String publicKey = "";

	public static void buy (String productID, String devPayload) {
		
		InAppPurchase.inAppPurchaseHelper.launchPurchaseFlow (Extension.mainActivity, productID, 1001, mPurchaseFinishedListener, devPayload);
		
	}
	
	public static void consume (final String purchaseJson, final String itemType, final String signature) 
	{
		Extension.callbackHandler.post (new Runnable () 
		{
			@Override public void run () 
			{
		
				try {
					final Purchase purchase = new Purchase(itemType, purchaseJson, signature);
					InAppPurchase.inAppPurchaseHelper.consumeAsync(purchase, mConsumeFinishedListener);
				} 
		
				catch (JSONException e) 
				{
					// This is not a normal consume failure, just a Json parsing error
					
					Extension.callbackHandler.post (new Runnable ()
					{
						@Override public void run () 
						{
							String resultJson = "{\"response\": -999, \"message\":\"Json Parse Error \"}";
							InAppPurchase.callback.call ("onFailedConsume", new Object[] { ("{\"result\":" + resultJson + ", \"product\":" + null  + "}") });
						}
					});

				} // catch
			} // run
		});

	}
	
	public static void queryInventory (final boolean querySkuDetails, String[] moreSkusArr) {
		final List<String> moreSkus = Arrays.asList(moreSkusArr); 
		Extension.mainActivity.runOnUiThread(new Runnable() {
			public void run() {
				try {
					InAppPurchase.inAppPurchaseHelper.queryInventoryAsync(querySkuDetails, moreSkus, mGotInventoryListener);
				} catch(Exception e) {
					Log.d("IAP", e.getMessage());
				}
			}
		});
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
					InAppPurchase.callback.call ("onFailedPurchase", new Object[] { ("{\"result\":" + result.toJsonString() + ", \"product\":" + ((purchase != null)? purchase.getOriginalJson() : "null") + "}") });
				}
			});
				
			} 
			else
			{
				Extension.callbackHandler.post (new Runnable ()
				{
					@Override public void run ()
					{
						// InAppPurchase.callback.call ("onPurchase", new Object[] { purchase.getOriginalJson(), purchase.getSignature(), purchase.getItemType() });
						Log.d("IAP-Marty", "got purchase response: " + purchase.getOriginalJson());
						InAppPurchase.callback.call ("onPurchase", new Object[] { purchase.getOriginalJson(), purchase.getItemType(), purchase.getSignature() });
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
