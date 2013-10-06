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
	private static String publicKey = "";
	
	
	public static void buy (String productID) {
		
		Log.i ("IAP", "Trying to buy: " + productID);
		
		if (BillingHelper.isBillingSupported ()) {
			
			BillingHelper.requestPurchase (Extension.mainContext, productID);
			
		} else {
			
			Log.i ("IAP", "Cannot buy item, billing not supported on this device");
			
		}
		
	}
	
	
	public static String getPublicKey (){
		
		return publicKey;
		
	}
	
	
	public static void initialize (String publicKey, final HaxeObject callback) {
		
		Log.i ("IAP", "Initializing billing service");
		
		InAppPurchase.callback = callback;
		setPublicKey (publicKey);
		
		Extension.callbackHandler.post (new Runnable () {
			
			@Override public void run () {
				
				Extension.mainActivity.startService (new Intent (Extension.mainContext, BillingService.class));
				
				Handler transactionHandler = new Handler () {
					
					public void handleMessage (Message msg) {
						
						if (BillingHelper.latestPurchase != null) {
							
							Log.i ("IAP", "Transaction complete");
							Log.i ("IAP", "Transaction status: " + BillingHelper.latestPurchase.purchaseState);
							Log.i ("IAP", "Attempted to purchase: " + BillingHelper.latestPurchase.productId);
							
							if (BillingHelper.latestPurchase.isPurchased ()) {
								
								Log.i ("IAP", "Transaction success");
								
								Extension.callbackHandler.post (new Runnable () {
									
									@Override public void run () {
										
										callback.call ("onPurchase", new Object[] { BillingHelper.latestPurchase.productId });
										
									}
									
								});
								
							} else {
								
								Log.i ("IAP", "Transaction failed");
								
								Extension.callbackHandler.post (new Runnable () {
									
									@Override public void run () {
										
										callback.call ("onFailedPurchase", new Object[] { BillingHelper.latestPurchase.productId });
										callback.call ("onCanceledPurchase", new Object[] { BillingHelper.latestPurchase.productId });
										
									}
									
								});
								
							}
							
						} else {
							
							Log.i ("IAP", "Transaction failed");
							
							Extension.callbackHandler.post (new Runnable () {
								
								@Override public void run () {
									
									callback.call ("onFailedPurchase", new Object[] { BillingSecurity.latestProductID });
									callback.call ("onCanceledPurchase", new Object[] { BillingSecurity.latestProductID });
									
								}
								
							});
							
						}
						
					};
					  
				};
				
				BillingHelper.setCompletedHandler (transactionHandler);
				
				Extension.callbackHandler.post (new Runnable () {
					 
					@Override public void run () {
						
						callback.call ("onStarted", new Object[] {});
						
					}
					
				});
				
			}
			
		});
		
	}
	
	
	public static void restore () {
		
		Log.i ("IAP", "Trying to restore purchases");
	
		if (BillingHelper.isBillingSupported ()) {
			
			BillingHelper.restoreTransactionInformation (BillingSecurity.generateNonce ());
			
		} else {
			
			Log.i ("IAP", "Cannot restore purchases, billing not supported on this device");
			
		}
		
	}
	
	
	public static void setPublicKey (String s) {
		
		publicKey = s;
		
	}
	
	
}