package org.haxe.extension.iap;

import android.opengl.GLSurfaceView;
import android.util.Log;
import android.util.Base64;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.ProductType;
import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.Purchase.PurchaseState;

import com.android.billingclient.api.ProductDetails;

import org.haxe.extension.Extension;
import org.haxe.extension.iap.util.BillingManager;
import org.haxe.extension.iap.util.BillingManager.BillingUpdatesListener;
import org.haxe.lime.HaxeObject;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.nio.charset.StandardCharsets;

public class InAppPurchase extends Extension {
	
	private static String TAG = "InAppPurchase";
	private static HaxeObject callback = null;
	private static BillingManager billingManager = null;
	private static String publicKey = "";
	private static UpdateListener updateListener = null;
	private static Map<String, Purchase> consumeInProgress = new HashMap<String, Purchase>();
	private static Map<String, Purchase> acknowledgePurchaseInProgress = new HashMap<String, Purchase>();

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
		public void onConsumeFinished(String token, final BillingResult result) {
			Log.e(TAG, "Consumption finished. Purchase token: " + token + ", result: " + result);
			final Purchase purchase = InAppPurchase.consumeInProgress.get(token);
			InAppPurchase.consumeInProgress.remove(token);
			if (result.getResponseCode() == BillingResponseCode.OK) {
				fireCallback("onConsume", new Object[] { purchase.getOriginalJson() });
			} else {
				fireCallback("onFailedConsume", new Object[] { ("{\"result\":" + result + ", \"product\":" + purchase.getOriginalJson() + "}") });
			}
		}

		@Override
		public void onAcknowledgePurchaseFinished(String token, final BillingResult result) {
			Log.d(TAG, "Consumption finished. Purchase token: " + token + ", result: " + result);
			final Purchase purchase = InAppPurchase.acknowledgePurchaseInProgress.get(token);
			InAppPurchase.acknowledgePurchaseInProgress.remove(token);
			if (result.getResponseCode() == BillingResponseCode.OK) {
				fireCallback("onAcknowledgePurchase", new Object[] { purchase.getOriginalJson() });
			} else {
				fireCallback("onFailedAcknowledgePurchase", new Object[] { ("{\"result\":" + result + ", \"product\":" + purchase.getOriginalJson() + "}") });
			}
		}

		@Override
		public void onPurchasesUpdated(List<Purchase> purchaseList, final BillingResult result) {
			Log.d(TAG, "onPurchasesUpdated: " + result);
			if (result.getResponseCode() == BillingResponseCode.OK)
			{
				for (Purchase purchase : purchaseList) 
				{
					if(purchase.getPurchaseState() == PurchaseState.PURCHASED) {
						//String sku = purchase.getSku();
						fireCallback("onPurchase", new Object[]{purchase.getOriginalJson(), "", purchase.getSignature()});
					}
				}
			}
			else
			{
				if (result.getResponseCode() ==  BillingResponseCode.USER_CANCELED)
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
		public void onQuerySkuDetailsFinished(List<ProductDetails> skuList, final BillingResult result) {
			Log.d(TAG, "onQuerySkuDetailsFinished: result: " + result.getDebugMessage());
			if (result.getResponseCode() == BillingResponseCode.OK) {
				String jsonResp =  "{ \"products\":[ ";
				for (ProductDetails sku : skuList) {
						//billing 4
						//jsonResp += sku.getOriginalJson() + ",";
						jsonResp += productDetailsToJson(sku) + ",";
				}
				jsonResp = jsonResp.substring(0, jsonResp.length() - 1);
				jsonResp += "]}";
				Log.d(TAG, "onQuerySkuDetailsFinished: " + jsonResp + ", result: " + result.getDebugMessage());
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
				if(purchase.getPurchaseState() == PurchaseState.PURCHASED) {
					for(String sku : purchase.getSkus()){
						jsonResp += "{" +
								"\"key\":\"" + sku +"\", " +
								"\"value\":" + purchase.getOriginalJson() + "," +
								"\"valueB64\":\"" + Base64.encodeToString(purchase.getOriginalJson().getBytes(StandardCharsets.UTF_8), Base64.DEFAULT) + "\", " + 
								"\"itemType\":\"\"," +
								"\"signature\":\"" + purchase.getSignature() + "\"},";
					}
				}
			}
			jsonResp = jsonResp.substring(0, jsonResp.length() - 1);
			jsonResp += "]}";
			Log.e(TAG, "onQueryPurchasesFinished: " + jsonResp);
			fireCallback("onQueryInventoryComplete", new Object[] { jsonResp });
		}

		public JSONObject productDetailsToJson(ProductDetails productDetails) {

			JSONObject resultObject = null;
	
			try {
	
				resultObject = new JSONObject();
				resultObject.put("productId", productDetails.getProductId());
				resultObject.put("type", productDetails.getProductType());
				resultObject.put("title", productDetails.getTitle());
				resultObject.put("name", productDetails.getName());
				resultObject.put("description", productDetails.getDescription());
				ProductDetails.OneTimePurchaseOfferDetails purchaseOfferDetails = productDetails.getOneTimePurchaseOfferDetails();
				if(purchaseOfferDetails != null) {
					resultObject.put("price", purchaseOfferDetails.getFormattedPrice());
					resultObject.put("price_amount_micros", purchaseOfferDetails.getPriceAmountMicros());
					resultObject.put("price_currency_code", purchaseOfferDetails.getPriceCurrencyCode());
				}
	
				List<ProductDetails.SubscriptionOfferDetails> subscriptionOfferDetailsList = productDetails.getSubscriptionOfferDetails();
				if(subscriptionOfferDetailsList != null) {
					JSONArray offersArray = new JSONArray();
	
					for (ProductDetails.SubscriptionOfferDetails offerDetails : subscriptionOfferDetailsList) {
						JSONObject offerJson = new JSONObject();
						if(offerDetails.getOfferId() != null)
							offerJson.put("offerId", offerDetails.getOfferId());
						offerJson.put("basePlanId", offerDetails.getBasePlanId());
						offerJson.put("offerTags", new JSONArray(offerDetails.getOfferTags()));
						offerJson.put("offerToken", offerDetails.getOfferToken());
	
						JSONArray pricingPhases = new JSONArray();
	
						for (ProductDetails.PricingPhase pricingPhase : offerDetails.getPricingPhases().getPricingPhaseList()) {
							JSONObject phaseJson = new JSONObject();
							phaseJson.put("billingCycleCount", pricingPhase.getBillingCycleCount());
							phaseJson.put("billingPeriod", pricingPhase.getBillingPeriod());
							phaseJson.put("formattedPrice", pricingPhase.getFormattedPrice());
							phaseJson.put("priceAmountMicros", pricingPhase.getPriceAmountMicros());
							phaseJson.put("priceCurrencyCode", pricingPhase.getPriceCurrencyCode());
							phaseJson.put("recurrenceMode", pricingPhase.getRecurrenceMode());
							pricingPhases.put(phaseJson);
						}
						offerJson.put("pricingPhases", pricingPhases);
	
	
						offersArray.put(offerJson);
	
					}
	
					resultObject.put("subscriptionOffers", offersArray);
	
				}
			}
			catch (JSONException e) {
				e.printStackTrace();
			}
	
			return resultObject;
		}
	}

	public static void buy (final String productID, final String devPayload) {
		// IabHelper.launchPurchaseFlow() must be called from the main activity's UI thread
		Extension.mainActivity.runOnUiThread(new Runnable()
		{
			@Override
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

	public static void acknowledgePurchase (final String purchaseJson, final String signature)
	{
		try
		{
			final Purchase purchase = new Purchase(purchaseJson, signature);
			if (!purchase.isAcknowledged()) {
				InAppPurchase.acknowledgePurchaseInProgress.put(purchase.getPurchaseToken(), purchase);
				InAppPurchase.billingManager.acknowledgePurchase(purchase.getPurchaseToken());
			}
		}
		catch(JSONException e)
		{
			fireCallback("onFailedAcknowledgePurchase", new Object[] {});
		}
	}

	private static void fireCallback(final String name, final Object[] payload)
	{
		try {
			if (Extension.mainView == null || InAppPurchase.callback == null) return;

			if (Extension.mainView instanceof GLSurfaceView)
			{
				GLSurfaceView view = (GLSurfaceView) Extension.mainView;
				view.queueEvent(new Runnable()
				{
					public void run()
					{
						InAppPurchase.callback.call(name, payload);
					}
				});
			}
			else
			{
				Extension.mainActivity.runOnUiThread(new Runnable()
				{
					@Override
					public void run()
					{
						InAppPurchase.callback.call(name, payload);
					}
				});
			}
		} catch (Exception e) {
			Log.e(TAG, "fireCallback:" + e.getMessage() + " " + e.toString());
		}
	}

	public static void querySkuDetails(String[] ids) {
		InAppPurchase.billingManager.querySkuDetailsAsync(ProductType.INAPP, Arrays.asList(ids));
	}
	
	public static String getPublicKey () {
		return publicKey;
	}
	
	
	public static void initialize (String publicKey, HaxeObject callback) {
		
		Log.e (TAG, "Initializing billing service");
		
		InAppPurchase.updateListener = new UpdateListener();
		InAppPurchase.publicKey = publicKey;
		InAppPurchase.callback = callback;
		
		BillingManager.BASE_64_ENCODED_PUBLIC_KEY = publicKey;
		InAppPurchase.billingManager = new BillingManager(Extension.mainActivity, InAppPurchase.updateListener);
	}
	
	public static void queryInventory () {
		Log.e ("IAP", "queryInventory");
		InAppPurchase.billingManager.queryPurchases();
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
