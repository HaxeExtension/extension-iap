//https://github.com/googlesamples/android-play-billing/blob/master/TrivialDrive_v2/shared-module/src/main/java/com/example/billingmodule/billing/BillingManager.java

/* Copyright (c) 2012 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.haxe.extension.iap.util;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.FeatureType;
import com.android.billingclient.api.BillingClient.ProductType;
import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingClientStateListener;

import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryProductDetailsParams.Product;

import com.android.billingclient.api.QueryPurchaseHistoryParams;
import com.android.billingclient.api.QueryPurchasesParams;

import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;

import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.ProductDetailsResponseListener;

import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.ConsumeResponseListener;

import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.PurchasesResponseListener;

import com.android.billingclient.api.BillingFlowParams.ProductDetailsParams;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

//import com.google.common.collect.ImmutableList;

/**
 * Handles all the interactions with Play Store (via Billing library), maintains connection to
 * it through BillingClient and caches temporary states/data if needed
 */
public class BillingManager implements PurchasesUpdatedListener {
    // Default value of mBillingClientResponseCode until BillingManager was not yeat initialized
    public static final int BILLING_MANAGER_NOT_INITIALIZED  = -1;

    private static final String TAG = "BillingManager hx:";

    private static BillingResult errorResult = BillingResult.newBuilder().setResponseCode(BILLING_MANAGER_NOT_INITIALIZED).setDebugMessage("ERROR").build();

    /** A reference to BillingClient **/
    private BillingClient mBillingClient;

    /**
     * True if billing service is connected now.
     */
    private boolean mIsServiceConnected;

    private final BillingUpdatesListener mBillingUpdatesListener;

    private final Activity mActivity;

    private final List<Purchase> mPurchases = new ArrayList<>();

    private Set<String> mTokensToBeConsumed;
    private Set<String> mTokensToBeAcknowledged;

    private int mBillingClientResponseCode = BILLING_MANAGER_NOT_INITIALIZED;

    private Map<String, ProductDetails> mSkuDetailsMap = new HashMap<>();

    /* BASE_64_ENCODED_PUBLIC_KEY should be YOUR APPLICATION'S PUBLIC KEY
     * (that you got from the Google Play developer console). This is not your
     * developer public key, it's the *app-specific* public key.
     *
     * Instead of just storing the entire literal string here embedded in the
     * program,  construct the key at runtime from pieces or
     * use bit manipulation (for example, XOR with some other string) to hide
     * the actual key.  The key itself is not secret information, but we don't
     * want to make it easy for an attacker to replace the public key with one
     * of their own and then fake messages from the server.
     */
    public static String BASE_64_ENCODED_PUBLIC_KEY = "CONSTRUCT_YOUR_KEY_AND_PLACE_IT_HERE";

    /**
     * Listener to the updates that happen when purchases list was updated or consumption of the
     * item was finished
     */
    public interface BillingUpdatesListener {
        void onBillingClientSetupFinished(final Boolean success);
        void onQueryPurchasesFinished(List<Purchase> purchases);
        void onConsumeFinished(String token, BillingResult result);
        void onAcknowledgePurchaseFinished(String token, BillingResult result);
        void onPurchasesUpdated(List<Purchase> purchases, BillingResult result);
        void onQuerySkuDetailsFinished(List<ProductDetails> skuDetailsList, BillingResult result);
    }

    /**
     * Listener for the Billing client state to become connected
     */
    public interface ServiceConnectedListener {
        void onServiceConnected(BillingResult result);
    }

    public BillingManager(Activity activity, final BillingUpdatesListener updatesListener) {
        Log.d(TAG, "Creating Billing client.");
        mActivity = activity;
        mBillingUpdatesListener = updatesListener;
        mBillingClient = BillingClient.newBuilder(mActivity).enablePendingPurchases().setListener(this).build();

        Log.d(TAG, "Starting setup.");
        //queryPurchases();
    }

    /**
     * Handle a callback that purchases were updated from the Billing library
     */
    @Override
    public void onPurchasesUpdated(BillingResult result, List<Purchase> purchases) {
        if (result.getResponseCode() == BillingResponseCode.OK) {
            mPurchases.clear();
            for (Purchase purchase : purchases) {
                handlePurchase(purchase);
            }
            mBillingUpdatesListener.onPurchasesUpdated(mPurchases, result);
        } else {
            Log.w(TAG, "onPurchasesUpdated() mPurchases: " + purchases);
            mBillingUpdatesListener.onPurchasesUpdated(purchases, result);
            Log.w(TAG, "onPurchasesUpdated() got unknown resultCode: " + result);
        }
    }

    /**
     * Start a purchase or subscription replace flow
     */
    public void initiatePurchaseFlow(final String skuId) {
        
        final ProductDetails skuDetail = mSkuDetailsMap.get(skuId);

        if(skuDetail == null)
        {
            Log.e(TAG, "skuId == null:" + skuId);

            ArrayList<String> ids = new ArrayList<String>();
            ids.add(skuId);
            querySkuDetailsAsync(ProductType.INAPP, ids);
        }
        else
        {
            
            Runnable purchaseFlowRequest = new Runnable() {
                @Override
                public void run() {
                    Log.e(TAG, "Launching in-app purchase flow.");
                    if(skuDetail != null) {

                        List<ProductDetailsParams> productDetailsParamsList = new ArrayList<>();

                        productDetailsParamsList.add(
                            ProductDetailsParams.newBuilder()
                            .setProductDetails(skuDetail)
                            .build());

                        BillingFlowParams billingFlowParams = BillingFlowParams.newBuilder()
                                .setProductDetailsParamsList(productDetailsParamsList)
                                .build();

                        // Launch the billing flow
                        mBillingClient.launchBillingFlow(mActivity, billingFlowParams);
                    }
                }
            };
    
            Runnable onError = new Runnable() {
                @Override
                public void run() {
                    mBillingUpdatesListener.onPurchasesUpdated(null, errorResult);
                };
            };
    
            executeServiceRequest(purchaseFlowRequest, onError);
        }
    }

    public Context getContext() {
        return mActivity;
    }

    /**
     * Clear the resources
     */
    public void destroy() {
        Log.d(TAG, "Destroying the manager.");

        if (mBillingClient != null && mBillingClient.isReady()) {
            mBillingClient.endConnection();
            mBillingClient = null;
        }
    }
     
    public void querySkuDetailsAsync(final String itemType, final List<String> skuList) {

        final List<Product> productList = new ArrayList<>();

        for (String productId : skuList) {
            productList.add(Product.newBuilder()
                    .setProductId(productId)
                    .setProductType(ProductType.INAPP)
                    .build());
        }

        // Creating a runnable from the request to use it inside our connection retry policy below
        Log.e(TAG, "Quering skuDetails:" + productList);
        Runnable queryRequest = new Runnable() {
            @Override
            public void run() {
                // Query the purchase async
                
                QueryProductDetailsParams params = QueryProductDetailsParams.newBuilder()
                    .setProductList(productList)
                    .build();

                mBillingClient.queryProductDetailsAsync(
                        params,
                        new ProductDetailsResponseListener() {
                            @Override
                            public void onProductDetailsResponse(BillingResult billingResult,
                                                                List<ProductDetails> skuDetailsList) {
                                Log.e(TAG, "onSkuDetailsResponse code:" + billingResult.getResponseCode());
                                mBillingUpdatesListener.onQuerySkuDetailsFinished(skuDetailsList, billingResult);
                                if (billingResult.getResponseCode() == BillingResponseCode.OK) {
                                    for (ProductDetails skuDetails : skuDetailsList) {
                                        mSkuDetailsMap.put(skuDetails.getProductId(), skuDetails);
                                        initiatePurchaseFlow(skuDetails.getProductId());
                                        break;
                                    }
                                }
                            }
                        });
            }
        };

        Runnable onError = new Runnable() {
            @Override
            public void run() {
                mBillingUpdatesListener.onQuerySkuDetailsFinished(null, errorResult);
            }
        };

        executeServiceRequest(queryRequest, onError);
    }

    public void consumeAsync(final String purchaseToken) {
        // If we've already scheduled to consume this token - no action is needed (this could happen
        // if you received the token when querying purchases inside onReceive() and later from
        // onActivityResult()
        if (mTokensToBeConsumed == null) {
            mTokensToBeConsumed = new HashSet<>();
        } else if (mTokensToBeConsumed.contains(purchaseToken)) {
            Log.i(TAG, "Token was already scheduled to be consumed - skipping...");
            return;
        }
        mTokensToBeConsumed.add(purchaseToken);

        final ConsumeParams consumeParams =
                ConsumeParams.newBuilder()
                        .setPurchaseToken(purchaseToken)
                        .build();

        // Generating Consume Response listener
        final ConsumeResponseListener onConsumeListener = new ConsumeResponseListener() {
            @Override
            public void onConsumeResponse(BillingResult billingResult, String purchaseToken) {
                // If billing service was disconnected, we try to reconnect 1 time
                // (feel free to introduce your retry policy here).
                mTokensToBeConsumed.remove(purchaseToken);
                mBillingUpdatesListener.onConsumeFinished(purchaseToken, billingResult);
            }
        };

        // Creating a runnable from the request to use it inside our connection retry policy below
        Runnable consumeRequest = new Runnable() {
            @Override
            public void run() {
                // Consume the purchase async
                Log.i(TAG, "Consuming:" + purchaseToken);
                mBillingClient.consumeAsync(consumeParams, onConsumeListener);
            }
        };

        Runnable onError = new Runnable() {
            @Override
            public void run() {
                mBillingUpdatesListener.onConsumeFinished(null, errorResult);
            }
        };

        executeServiceRequest(consumeRequest, onError);
    }

    public void acknowledgePurchase(final String purchaseToken) {
        // If we've already scheduled to consume this token - no action is needed (this could happen
        // if you received the token when querying purchases inside onReceive() and later from
        // onActivityResult()
        if (mTokensToBeAcknowledged == null) {
            mTokensToBeAcknowledged = new HashSet<>();
        } else if (mTokensToBeAcknowledged.contains(purchaseToken)) {
            Log.i(TAG, "Token was already scheduled to be consumed - skipping...");
            return;
        }
        mTokensToBeAcknowledged.add(purchaseToken);

        final AcknowledgePurchaseParams acknowledgePurchaseParams =
                AcknowledgePurchaseParams.newBuilder()
                        .setPurchaseToken(purchaseToken)
                        .build();

        // Generating Consume Response listener
        final AcknowledgePurchaseResponseListener acknowledgePurchaseResponseListener = new AcknowledgePurchaseResponseListener() {
            @Override
            public void onAcknowledgePurchaseResponse(BillingResult billingResult) {
                // If billing service was disconnected, we try to reconnect 1 time
                // (feel free to introduce your retry policy here).
                mTokensToBeAcknowledged.remove(purchaseToken);
                mBillingUpdatesListener.onAcknowledgePurchaseFinished(purchaseToken, billingResult);
            }
        };

        // Creating a runnable from the request to use it inside our connection retry policy below
        Runnable acknowledgeRequest = new Runnable() {
            @Override
            public void run() {
                // Consume the purchase async
                Log.i(TAG, "Consuming:" + purchaseToken);
                mBillingClient.acknowledgePurchase(acknowledgePurchaseParams, acknowledgePurchaseResponseListener);
            }
        };

        Runnable onError = new Runnable() {
            @Override
            public void run() {
                mBillingUpdatesListener.onAcknowledgePurchaseFinished(null, errorResult);
            }
        };

        executeServiceRequest(acknowledgeRequest, onError);
    }

    /**
     * Returns the value Billing client response code or BILLING_MANAGER_NOT_INITIALIZED if the
     * clien connection response was not received yet.
     */
    public int getBillingClientResponseCode() {
        return mBillingClientResponseCode;
    }

    /**
     * Handles the purchase
     * <p>Note: Notice that for each purchase, we check if signature is valid on the client.
     * It's recommended to move this check into your backend.
     * See {@link Security#verifyPurchase(String, String, String)}
     * </p>
     * @param purchase Purchase to be handled
     */
    private void handlePurchase(Purchase purchase) {
        if (!verifyValidSignature(purchase.getOriginalJson(), purchase.getSignature())) {
            Log.i(TAG, "Got a purchase: " + purchase + "; but signature is bad. Skipping...");
            return;
        }

        Log.d(TAG, "Got a verified purchase: " + purchase);

        mPurchases.add(purchase);
    }

    /**
     * Handle a result from querying of purchases and report an updated list to the listener
     */
    private void onQueryPurchasesFinished(BillingResult result, List<Purchase> purchases ) {
        // Have we been disposed of in the meantime? If so, or bad result code, then quit
        if (mBillingClient == null || result.getResponseCode() != BillingResponseCode.OK) {
            Log.e(TAG, "Billing client was null or result code (" + result.getResponseCode()
                    + ") was bad - quitting");
            mBillingUpdatesListener.onBillingClientSetupFinished(false);
            return;
        }

        Log.e(TAG, "Query inventory was successful.");
        mBillingUpdatesListener.onQueryPurchasesFinished(purchases);
        mBillingUpdatesListener.onBillingClientSetupFinished(true);
    }

    /**
     * Checks if subscriptions are supported for current client
     * <p>Note: This method does not automatically retry for RESULT_SERVICE_DISCONNECTED.
     * It is only used in unit tests and after queryPurchases execution, which already has
     * a retry-mechanism implemented.
     * </p>
     */
    public boolean areSubscriptionsSupported() {
        BillingResult response = mBillingClient.isFeatureSupported(FeatureType.SUBSCRIPTIONS);
        if (response.getResponseCode() != BillingResponseCode.OK) {
            Log.w(TAG, "areSubscriptionsSupported() got an error response: " + response.getResponseCode());
        }
        return response.getResponseCode() == BillingResponseCode.OK;
    }

    /**
     * Query purchases across various use cases and deliver the result in a formalized way through
     * a listener
     */
    public void queryPurchases() {
        Runnable queryToExecute = new Runnable() {
            @Override
            public void run() {
                long time = System.currentTimeMillis();
                
                //PurchasesResult purchasesResult = mBillingClient.queryPurchases(SkuType.INAPP);
                
                mBillingClient.queryPurchasesAsync(
                    QueryPurchasesParams.newBuilder().setProductType(ProductType.INAPP).build(),
                    new PurchasesResponseListener() {
                        public void onQueryPurchasesResponse(
                                BillingResult billingResult,
                                List<Purchase> purchases) {
                                    // Process the result
                                    Log.i(TAG, "purchasesResult:" + billingResult);

                                    onQueryPurchasesFinished(billingResult, purchases);
                        }
                    }
                );

                
                Log.i(TAG, "Querying purchases elapsed time: " + (System.currentTimeMillis() - time)
                        + "ms");

                /*
                // If there are subscriptions supported, we add subscription rows as well
                if (areSubscriptionsSupported()) {
                    PurchasesResult subscriptionResult
                            = mBillingClient.queryPurchases(SkuType.SUBS);
                    Log.i(TAG, "Querying purchases and subscriptions elapsed time: "
                            + (System.currentTimeMillis() - time) + "ms");
                    Log.i(TAG, "Querying subscriptions result code: "
                            + subscriptionResult.getResponseCode()
                            + " res: " + subscriptionResult.getPurchasesList().size());

                    if (subscriptionResult.getResponseCode() == BillingResponse.OK) {
                        purchasesResult.getPurchasesList().addAll(
                                subscriptionResult.getPurchasesList());
                    } else {
                        Log.e(TAG, "Got an error response trying to query subscription purchases");
                    }
                } else if (purchasesResult.getResponseCode() == BillingResponse.OK) {
                    Log.i(TAG, "Skipped subscription purchases query since they are not supported");
                } else {
                    Log.w(TAG, "queryPurchases() got an error response code: "
                            + purchasesResult.getResponseCode());
                }
                */
                
            }
        };

        Runnable onError = new Runnable() {
            @Override
            public void run() {
                mBillingUpdatesListener.onBillingClientSetupFinished(false);
            }
        };
        executeServiceRequest(queryToExecute, onError);
    }

    public void startServiceConnection(final Runnable executeOnSuccess, final Runnable executeOnError) {
        mBillingClient.startConnection(new BillingClientStateListener() {
            @Override
            public void onBillingSetupFinished(BillingResult billingResponse) {
                Log.d(TAG, "Setup finished. Response code: " + billingResponse.getResponseCode());
                mBillingClientResponseCode = billingResponse.getResponseCode();

                if (billingResponse.getResponseCode() == BillingResponseCode.OK) {
                    mIsServiceConnected = true;
                    if (executeOnSuccess != null) {
                        executeOnSuccess.run();
                    }
                }
                else {
                    if (executeOnError != null) {
                        executeOnError.run();
                    }
                    mIsServiceConnected = false;
                }
            }

            @Override
            public void onBillingServiceDisconnected() {
                Log.d(TAG, "OnBillingServiceDisconnected");
                mIsServiceConnected = false;
            }
        });
    }

    private void executeServiceRequest(Runnable runnable, Runnable onError) {
        if (mIsServiceConnected) {
            runnable.run();
        } else {
            // If billing service was disconnected, we try to reconnect 1 time.
            // (feel free to introduce your retry policy here).
            startServiceConnection(runnable, onError);
        }
    }

    /**
     * Verifies that the purchase was signed correctly for this developer's public key.
     * <p>Note: It's strongly recommended to perform such check on your backend since hackers can
     * replace this method with "constant true" if they decompile/rebuild your app.
     * </p>
     */
    private boolean verifyValidSignature(String signedData, String signature) {
        try {
            return Security.verifyPurchase(BASE_64_ENCODED_PUBLIC_KEY, signedData, signature);
        } catch (IOException e) {
            Log.e(TAG, "Got an exception trying to validate a purchase: " + e);
            return false;
        }
        
    }
}
