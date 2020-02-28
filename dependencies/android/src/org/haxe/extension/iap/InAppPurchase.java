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
import com.android.billingclient.api.BillingClient.SkuType;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.SkuDetails;
import org.haxe.extension.iap.util.BillingManager.BillingUpdatesListener;

import org.json.JSONException;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.opengl.GLSurfaceView;

public class InAppPurchase extends Extension {
	
	private static String TAG = "BillingManager";
	private static HaxeObject callback = null;
	private static BillingManager billingManager = null;
	private static String publicKey = "";
	private static UpdateListener updateListener = null;
	private static Map<String, Purchase> consumeInProgress = new HashMap<String, Purchase>();

	private static class UpdateListener implements BillingUpdatesListener {
		@Override
		public void onBillingClientSetupFinished(final Boolean success) {
			if (success) {
				fireCallback("onStarted", new Object[] { "Success" });
			}
			else {
				fireCallback("onStarted", new Object[] { "Failure" });
			}
		}

		@Override
		public void onConsumeFinished(String token, final @BillingResponse int result) {
			Log.d(TAG, "Consumption finished. Purchase token: " + token + ", result: " + result);
			final Purchase purchase = InAppPurchase.consumeInProgress.get(token);
			InAppPurchase.consumeInProgress.remove(token);
			if (result == BillingResponse.OK) {
				fireCallback("onConsume", new Object[] { purchase.getOriginalJson() });
			} else {
				fireCallback("onFailedConsume", new Object[] { ("{\"result\":" + result + ", \"product\":" + purchase.getOriginalJson() + "}") });
			}
		}

		@Override
		public void onPurchasesUpdated(List<Purchase> purchaseList, final @BillingResponse int result) {
			Log.d(TAG, "onPurchasesUpdated: " + result);
			if (result == BillingResponse.OK)
			{
				for (Purchase purchase : purchaseList) 
				{
					String sku = purchase.getSku();
					fireCallback("onPurchase", new Object[] { purchase.getOriginalJson(), "", purchase.getSignature() });
				}
			}
			else
			{
				if (result ==  BillingResponse.USER_CANCELED) 
				{
					fireCallback("onCanceledPurchase", new Object[] { "canceled" });
				}
				else
				{
					String message = "{\"result\":{\"message\":\"" + result + "\"}}";
					Log.d(TAG, "onFailedPurchase: " + message);
					fireCallback("onFailedPurchase", new Object[] { (message) });
				}
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
				fireCallback("onRequestProductDataComplete", new Object[] { jsonResp });
			}
			else {
				fireCallback("onRequestProductDataComplete", new Object[] { "Failure" });
			}
		}

		@Override
		public void onQueryPurchasesFinished(List<Purchase> purchaseList) {
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
			fireCallback("onQueryInventoryComplete", new Object[] { jsonResp });
		}
	}

	public static void buy (final String productID, final String devPayload) {
		// IabHelper.launchPurchaseFlow() must be called from the main activity's UI thread
		Extension.mainActivity.runOnUiThread(new Runnable()
		{
			public void run()
			{
				InAppPurchase.billingManager.initiatePurchaseFlow(productID);
			}
		});
	}
	
	public static void consume (final String purchaseJson, final String signature) 
	{
		try
		{
			final Purchase purchase = new Purchase(purchaseJson, signature);
			InAppPurchase.consumeInProgress.put(purchase.getPurchaseToken(), purchase);
			InAppPurchase.billingManager.consumeAsync(purchase.getPurchaseToken());
		}
		catch(JSONException e)
		{
			fireCallback("onFailedConsume", new Object[] {});
		}
	}

	private static void fireCallback(final String name, final Object[] payload)
	{
		if (Extension.mainView == null) return;

		if (Extension.mainView instanceof GLSurfaceView)
		{
			GLSurfaceView view = (GLSurfaceView) Extension.mainView;
			view.queueEvent(new Runnable()
			{
				public void run()
				{
					if (InAppPurchase.callback != null)
					{
						InAppPurchase.callback.call(name, payload);
					}
				}
			});
		}
		else
		{
			if (InAppPurchase.callback != null)
			{
				InAppPurchase.callback.call(name, payload);
			}
		}
	}

	public static void querySkuDetails(String[] ids) {
		InAppPurchase.billingManager.querySkuDetailsAsync(SkuType.INAPP, Arrays.asList(ids));
	}
	
	public static String getPublicKey () {
		return publicKey;
	}
	
	
	public static void initialize (String publicKey, HaxeObject callback) {
		
		Log.i (TAG, "Initializing billing service");
		
		InAppPurchase.updateListener = new UpdateListener();
		InAppPurchase.publicKey = publicKey;
		InAppPurchase.callback = callback;
		
		BillingManager.BASE_64_ENCODED_PUBLIC_KEY = publicKey;
		InAppPurchase.billingManager = new BillingManager(Extension.mainActivity, InAppPurchase.updateListener);
	}
	
	
	@Override public void onDestroy () {
		if (InAppPurchase.billingManager != null) {
			InAppPurchase.billingManager.destroy();
			InAppPurchase.billingManager = null;
		}
	}
	
	
	public static void setPublicKey (String s) {
		publicKey = s;
		BillingManager.BASE_64_ENCODED_PUBLIC_KEY = publicKey;
	}
}
