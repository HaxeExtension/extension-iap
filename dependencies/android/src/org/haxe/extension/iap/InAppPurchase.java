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
import com.android.billingclient.api.BillingClient.BillingResponse;
import com.android.billingclient.api.Purchase;
import org.haxe.extension.iap.util.BillingManager.BillingUpdatesListener;

import org.json.JSONException;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

public class InAppPurchase extends Extension {
	
	private static String TAG = "IAP";
	private static HaxeObject callback = null;
	private static BillingManager billingManager = null;
	private static String publicKey = "";
	private static UpdateListener updateListener = null;
	private static Map<String, Purchase> consumeInProgress = new HashMap<String, Purchase>();

	private static class UpdateListener implements BillingUpdatesListener {
        @Override
        public void onBillingClientSetupFinished() {
			Extension.callbackHandler.post (new Runnable () {
				@Override public void run () {
					InAppPurchase.callback.call ("onStarted", new Object[] { "Success" });
				}
			});
			//TODO: handle failed
			//InAppPurchase.callback.call ("onStarted", new Object[] { "Failure" });
        }

		@Override
		public void onConsumeFinished(String token, @BillingResponse int result) {
			Log.d(TAG, "Consumption finished. Purchase token: " + token + ", result: " + result);
			final Purchase purchase = InAppPurchase.consumeInProgress.get(token);
			InAppPurchase.consumeInProgress.remove(token);
			if (result == BillingResponse.OK) {
				Extension.callbackHandler.post (new Runnable ()
				{
					@Override public void run ()
					{
						InAppPurchase.callback.call ("onConsume", new Object[] { purchase.getOriginalJson() });
					}
				});
			} else {
				Extension.callbackHandler.post (new Runnable ()
				{
					@Override public void run () 
					{
						InAppPurchase.callback.call ("onFailedConsume", new Object[] { ("{\"result\":" + result + ", \"product\":" + purchase.getOriginalJson() + "}") });
					}
				});
			}
		}

        @Override
        public void onPurchasesUpdated(List<Purchase> purchaseList) {
            for (Purchase purchase : purchaseList) {
                switch (purchase.getSku()) {
                }
            }
        }
    }

	public static void buy (final String productID, final String devPayload) {
		// IabHelper.launchPurchaseFlow() must be called from the main activity's UI thread
		Extension.mainActivity.runOnUiThread(new Runnable() {
				public void run() {
					try {
						InAppPurchase.billingManager.launchPurchaseFlow (Extension.mainActivity, productID, 1001, mPurchaseFinishedListener, devPayload);
					} catch (Exception exception) {
						
					}
				}
			});
	}
	
	public static void consume (final String purchaseJson, final String signature) 
	{
		Extension.callbackHandler.post (new Runnable () 
		{
			@Override public void run () 
			{
				final Purchase purchase = new Purchase(purchaseJson, signature);
				InAppPurchase.consumeInProgress.put(purchase.getPurchaseToken(), purchase);
				InAppPurchase.billingManager.consumeAsync(purchase.getPurchaseToken());
			} // run
		});

	}
	
	public static void queryInventory (final boolean querySkuDetails, String[] moreSkusArr) {
		final List<String> moreSkus = Arrays.asList(moreSkusArr); 
		Extension.mainActivity.runOnUiThread(new Runnable() {
			public void run() {
				try {
					InAppPurchase.billingManager.queryInventoryAsync(querySkuDetails, moreSkus, mGotInventoryListener);
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
		
		InAppPurchase.updateListener = new UpdateListener();
		InAppPurchase.publicKey = publicKey;
		InAppPurchase.callback = callback;
		
		BillingManager.BASE_64_ENCODED_PUBLIC_KEY = publicKey;
		InAppPurchase.billingManager = new BillingManager(Extension.mainActivity, InAppPurchase.updateListener);
	}
	
	
	@Override public void onDestroy () {
		if (InAppPurchase.billingManager != null) {
			InAppPurchase.billingManager = null;
		}
	}
	
	
	public static void setPublicKey (String s) {
		publicKey = s;
		BillingManager.BASE_64_ENCODED_PUBLIC_KEY = publicKey;
	}
	

/*	
	static IabHelper.QueryInventoryFinishedListener mGotInventoryListener = new IabHelper.QueryInventoryFinishedListener() {
	   
		public void onQueryInventoryFinished(final IabResult result, final Inventory inventory) {
			Log.i ("IAP", "onQueryInventoryFinished");
			Log.i ("IAP", Boolean.toString(result.isFailure()));

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
			  //Log.i ("IAP", inventory.toJsonString());
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
					if (result.getResponse() == IabHelper.IABHELPER_USER_CANCELLED) {
						InAppPurchase.callback.call ("onCanceledPurchase", new Object[] { ((purchase == null) ? "null" : purchase.getPackageName()) });
					} else {
						InAppPurchase.callback.call ("onFailedPurchase", new Object[] { ("{\"result\":" + result.toJsonString() + ", \"product\":" + ((purchase != null)? purchase.getOriginalJson() : "null") + "}") });
					}
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
*/
	
	
	
}
