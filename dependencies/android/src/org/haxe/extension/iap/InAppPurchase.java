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
		public void onBillingClientSetupFinished(final Boolean success) {
			if (success) {
				InAppPurchase.callback.call("onStarted", new Object[] { "Success" });
			}
			else {
				InAppPurchase.callback.call("onStarted", new Object[] { "Failure" });
			}
		}

		@Override
		public void onConsumeFinished(String token, @BillingResponse int result) {
			Log.d(TAG, "Consumption finished. Purchase token: " + token + ", result: " + result);
			final Purchase purchase = InAppPurchase.consumeInProgress.get(token);
			InAppPurchase.consumeInProgress.remove(token);
			if (result == BillingResponse.OK) {
				InAppPurchase.callback.call("onConsume", new Object[] { purchase.getOriginalJson() });
			} else {
				InAppPurchase.callback.call("onFailedConsume", new Object[] { ("{\"result\":" + result + ", \"product\":" + purchase.getOriginalJson() + "}") });
			}
		}

		@Override
		public void onPurchasesUpdated(List<Purchase> purchaseList, final @BillingResponse int result) {
			Log.d(TAG, "onPurchasesUpdated: " + result);
			if (result != BillingResponse.OK)
			{
				for (String purchase : purchaseInProgress) {
					if (result ==  BillingResponse.USER_CANCELED) {
						InAppPurchase.callback.call("onCanceledPurchase", new Object[] { purchase });
					}
					else {
						Log.d(TAG, "onFailedPurchase: " + "{\"result\":{\"message\":\"" + result + "\"}, \"product\":{\"productId:\""  + purchase + "\"}}");
						InAppPurchase.callback.call("onFailedPurchase", new Object[] { ("{\"result\":{\"message\":\"" + result + "\"}, \"product\":{\"productId\":\""  + purchase + "\"}}") });
					}
				}
				purchaseInProgress.clear();
				return;
			}
			
			for (Purchase purchase : purchaseList) {
					String sku = purchase.getSku();
					Boolean wasInProgress = purchaseInProgress.remove(sku);
					InAppPurchase.callback.call ("onPurchase", new Object[] { purchase.getOriginalJson(), "", purchase.getSignature() });
			}
		}

		@Override
		public void onQuerySkuDetailsFinished(List<SkuDetails> skuList, final @BillingResponse int result) {
			Log.d(TAG, "onQuerySkuDetailsFinished: result: " + result);
			if (result == BillingResponse.OK) {
				String jsonResp =  "{ \"products\":[ ";
				for (SkuDetails sku : skuList) {
						jsonResp += sku.getOriginalJson() + ",";
				}
				jsonResp = jsonResp.substring(0, jsonResp.length() - 1);
				jsonResp += "]}";
				Log.d(TAG, "onQuerySkuDetailsFinished: " + jsonResp + ", result: " + result);
				InAppPurchase.callback.call ("onRequestProductDataComplete", new Object[] { jsonResp });
			}
			else {
				InAppPurchase.callback.call ("onRequestProductDataComplete", new Object[] { "Failure" });
			}
		}

		@Override
		public void onQueryPurchasesFinished(List<Purchase> purchaseList, final @BillingResponse int result) {
			Log.d(TAG, "onQueryPurchasesFinished: result: " + result);
			if (result == BillingResponse.OK) {
				String jsonResp =  "{ \"purchases\":[ ";
				for (Purchase purchase : purchaseList) {
						jsonResp += "{" +
						"\"key\":\"" + purchase.getSku() + "\", " + 
						"\"value\":" + purchase.getOriginalJson() + "," + 
						"\"itemType\":\"\"," + 
						"\"signature\":\"" + purchase.getSignature() + "\"},";
				}
				jsonResp = jsonResp.substring(0, jsonResp.length() - 1);
				jsonResp += "]}";
				InAppPurchase.callback.call ("onQueryInventoryComplete", new Object[] { jsonResp });
			}
			else {
				InAppPurchase.callback.call ("onQueryInventoryComplete", new Object[] { "Failure" });
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
}
