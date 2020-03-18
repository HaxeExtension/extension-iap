[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md) [![Haxelib Version](https://img.shields.io/github/tag/openfl/extension-iap.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/extension-iap) [![Build Status](https://img.shields.io/travis/openfl/extension-iap.svg?style=flat)](https://travis-ci.org/openfl/extension-iap)

# IAP

Provides an access to in-app purchases (iOS) and in-app billing (Android) for OpenFL projects using a common API.

# Installation

You can easily install IAP using haxelib:

    haxelib install extension-iap

To add it to a Lime or OpenFL project, add this to your project file:

    <haxelib name="extension-iap" />

# Usage

## 1. Initialize iap:

```haxe
// required only for Google Play
var publicKey:String = "";

#if android
publicKey = "ANDROID_PUBLIC_KEY";
#elseif ios
publicKey = "";
#end

function onPurchaseInitSuccess(e:IAPEvent) {
    // OK
}

function onPurchaseInitFailed(e:IAPEvent) {
    // reason: e.message
}

IAP.addEventListener(IAPEvent.PURCHASE_INIT, onPurchaseInitSuccess);
IAP.addEventListener(IAPEvent.PURCHASE_INIT_FAILED, onPurchaseInitFailed);

IAP.manualTransactionMode = true;
IAP.initialize(publicKey);
```

## 2. Receive shop items data:
```haxe
function onProductsDataComplete(e:IAPEvent) {
    // e.productsData is array of ProductDetails
    for (data in e.productsData) {
        // data.productId, data.price, data.localizedPrice, ...
    }
}

function onProductsDataFailed(e:IAPEvent) {
    // reason: e.message
}

IAP.addEventListener(IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE, onProductsDataComplete);
IAP.addEventListener(IAPEvent.PURCHASE_PRODUCT_DATA_FAILED, onProductsDataFailed);

var productIds:Array<String> = ["item_id_1", "item_id_2", ...];
IAP.requestProductData(productIds);
```

## 3. Perform purchase:
```haxe
function onPurchaseSuccess(e:IAPEvent):Void {
    // purchase was completed
    // productID: e.productID
    // e.purchase - pass it for consuming
    // or you can get it from inventory after purchasing: IAP.inventory.getPurchase(productID)
}

function onPurchaseFail(e:IAPEvent):Void {
    // purchase was failed, reason: e.message
}

function onPurchaseCancel(e:IAPEvent):Void {
    // purchase was cancelled by user
}

IAP.addEventListener(IAPEvent.PURCHASE_SUCCESS, onPurchaseSuccess);
IAP.addEventListener(IAPEvent.PURCHASE_FAILURE, onPurchaseFail);
IAP.addEventListener(IAPEvent.PURCHASE_CANCEL, onPurchaseCancel);

IAP.purchase(productId);
```

## 4. Consume purchase:
```haxe
function onConsumeSuccess(e:IAPEvent):Void {
    // purchase was consumed and not in IAP.inventory anymore
}

function onConsumeFail(e:IAPEvent):Void {
    // reason: e.message
}

IAP.addEventListener(IAPEvent.PURCHASE_CONSUME_SUCCESS, onConsumeSuccess);
IAP.addEventListener(IAPEvent.PURCHASE_CONSUME_FAILURE, onConsumeFail);

IAP.consume(purchaseData);
```

# Development Builds

Clone the IAP repository:

    git clone https://github.com/openfl/extension-iap

Tell haxelib where your development copy of IAP is installed:

    haxelib dev extension-iap extension-iap

You can build the binaries using "lime rebuild"

    lime rebuild extension-iap ios

To return to release builds:

    haxelib dev extension-iap
