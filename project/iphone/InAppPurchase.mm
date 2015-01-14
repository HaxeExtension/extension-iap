#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h> 
#include "InAppPurchase.h"
#include "InAppPurchaseEvent.h"


extern "C" void sendPurchaseEvent(const char* type, const char* data);
extern "C" void sendPurchaseFinishEvent(const char* type, const char* productID, const char* transactionID, double transactionDate, const char* receipt);
extern "C" void sendPurchaseDownloadEvent(const char* type, const char* productID, const char* transactionID, const char* downloadPath, const char* downloadVersion, const char* downloadProgress);
extern "C" void sendPurchaseProductDataEvent(const char* type, const char* productID, const char* localizedTitle, const char* localizedDescription, int priceAmountMicros, const char* localizedPrice, const char* priceCurrencyCode);


@interface InAppPurchase: NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    SKProduct* myProduct;
    SKProductsRequest* productsRequest;
	NSString* productID;
	bool manualTransactionMode;
}

- (void)initInAppPurchase;
- (void)restorePurchases;
- (BOOL)canMakePurchases;
- (void)purchaseProduct:(NSString*)productIdentifiers;
- (void)requestProductData:(NSString*)productIdentifiers;
- (void)finishTransactionManually:(NSString *)transactionID;

@property bool manualTransactionMode;
@end

@implementation InAppPurchase
@synthesize manualTransactionMode;

#pragma Public methods 

- (void)initInAppPurchase 
{
	manualTransactionMode = false;
	NSLog(@"xxxxxxx purchase init");
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	sendPurchaseEvent("started", "");
}

- (void)restorePurchases 
{
	NSLog(@"starting restore");
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
} 

- (void)purchaseProduct:(NSString*)productIdentifiers
{
	if(productsRequest != NULL)
	{
		NSLog(@"Can't start a purchase while performing a previous transaction.");
		return;
	}
	
	productID = productIdentifiers;
	productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productID]];
	productsRequest.delegate = self;
	[productsRequest start];
} 

- (void)requestProductData:(NSString*)productIdentifiers
{
	if(productsRequest != NULL)
	{
		NSLog(@"Can't request product data while performing a previous transaction.");
		return;
	}

	if(productID) 
	{
		productID = nil;
	}
		
	NSSet *productIdentifiersSet = [NSSet setWithArray:[productIdentifiers componentsSeparatedByString:@","] ];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiersSet];
    productsRequest.delegate = self;
    [productsRequest start];
    
    // we will release the request object in the delegate callback
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods 

- (void)request:(SKProductsRequest *)request didFailWithError:(NSError *)error
{
	NSLog(@"Error: %@",error);
	if( productsRequest == request ) productsRequest = NULL;
	
	if(productID)
	{
		sendPurchaseEvent("failed", [productID UTF8String]);
	}
	else
	{
		sendPurchaseEvent("productDataFailed", [error.localizedDescription UTF8String]);
	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse*)response
{   	
	int count = [response.products count];
    NSLog(@"productsRequest");
	NSLog(@"Number of Products: %i", count);
    
	if(count > 0) 
    {
		if (productID)
		{
            NSLog(@"attempting to add payment");
			myProduct = [response.products objectAtIndex:0];
            NSLog(@"%@", myProduct.productIdentifier);
			// A payment has been done
			SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:myProduct];
            payment.quantity = 1;
			[[SKPaymentQueue defaultQueue] addPayment:payment];
		}
		else
		{
			// A products data request has been responded
			
			for(SKProduct *prod in response.products)
			{
				// localise the pricing
				NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
				[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
				[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
				[numberFormatter setLocale:prod.priceLocale];
				NSString *formattedPrice = [numberFormatter stringFromNumber:prod.price];
				[numberFormatter release];
				
				NSString *priceCurrencyCode = [prod.priceLocale objectForKey:NSLocaleCurrencyCode];

				int priceAmountMicros = [[prod.price decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"1000000"]] intValue];			

				sendPurchaseProductDataEvent("productData", [prod.productIdentifier UTF8String], [prod.localizedTitle UTF8String], [prod.localizedDescription UTF8String], priceAmountMicros, [formattedPrice UTF8String], [priceCurrencyCode UTF8String]);

			}
			
			sendPurchaseEvent("productDataComplete", nil);
		}
	} 
    
    else 
    {
		NSLog(@"No products are available");
	}
    
    //[productsRequest release];
    productsRequest = NULL;
}

- (void)finishTransactionManually:(NSString *)transactionID
{
	if (manualTransactionMode && [[SKPaymentQueue defaultQueue] transactions]) {
		NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
		
		if ([transactions containsObject:transactionID]) {
			//[self finishTransaction:[transactions objectAtIndex:[transactions indexOfObject:transactionID]]  wasSuccessful:YES];
			[[SKPaymentQueue defaultQueue] finishTransaction:[transactions objectAtIndex:[transactions indexOfObject:transactionID]]];
		}
		
		//[transactions release];
	}
}

- (void)finishTransaction:(SKPaymentTransaction*)transaction wasSuccessful:(BOOL)wasSuccessful
{
    if (!manualTransactionMode) [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if(wasSuccessful)
    {
    	NSLog(@"Successful Purchase");
        NSString* receiptString = [[NSString alloc] initWithString:transaction.payment.productIdentifier];
        
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
        NSString *jsonObjectString = [receipt base64EncodedStringWithOptions:0];

        sendPurchaseFinishEvent("success", [transaction.payment.productIdentifier UTF8String], [transaction.transactionIdentifier UTF8String], ([transaction.transactionDate timeIntervalSince1970] * 1000), [jsonObjectString UTF8String]);
    }
    
    else
    {
    	NSLog(@"Failed Purchase");
        if (transaction.error.code != SKErrorPaymentCancelled)
        {
            NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
        }
        sendPurchaseEvent("failed", [transaction.payment.productIdentifier UTF8String]);
    }
}

- (void)completeTransaction:(SKPaymentTransaction*)transaction
{
	
	if (transaction.downloads) {
		sendPurchaseDownloadEvent("downloadStart", [transaction.payment.productIdentifier UTF8String], [transaction.transactionIdentifier UTF8String], nil, nil, nil);
		[[SKPaymentQueue defaultQueue] startDownloads:transaction.downloads];
		
	} else {
		NSLog(@"Finish Transaction");
		[self finishTransaction:transaction wasSuccessful:YES];
	}
}

/*
- (void)restoreTransaction:(SKPaymentTransaction*)transaction
{
	NSLog(@"Restoring Transaction");
	sendPurchaseEvent("restore", [transaction.payment.productIdentifier UTF8String]);
    [self finishTransaction:transaction wasSuccessful:YES];
}
 */

- (void)failedTransaction:(SKPaymentTransaction*)transaction
{
    if(transaction.error.code != SKErrorPaymentCancelled)
    {
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    
    else
    {
    	NSLog(@"Canceled Purchase");
    	sendPurchaseEvent("cancel", [transaction.payment.productIdentifier UTF8String]);
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray*)transactions
{
	
	NSLog(@"updatedTransactions");
	for(SKPaymentTransaction *transaction in transactions)
    {
        switch(transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
			case SKPaymentTransactionStateRestored:
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
                
            /*case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            */
            default:
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray*)downloads
{
    for (SKDownload *download in downloads)
    {
        switch (download.downloadState) {
            case SKDownloadStateActive:
                NSLog(@"Download progress = %f and Download time: %f", download.progress, download.timeRemaining);
				
				sendPurchaseDownloadEvent("downloadProgress", [download.contentIdentifier UTF8String], [download.transaction.transactionIdentifier UTF8String], [[download.contentURL absoluteString] UTF8String], [download.contentVersion UTF8String], [[NSString stringWithFormat:@"%f", download.progress] UTF8String]);
				
                break;
            case SKDownloadStateFinished:
                NSLog(@"Download complete: %@",download.contentURL);
				
				sendPurchaseDownloadEvent("downloadComplete", [download.contentIdentifier UTF8String], [download.transaction.transactionIdentifier UTF8String], [[download.contentURL absoluteString] UTF8String], [download.contentVersion UTF8String], nil);
				
				[self finishTransaction:download.transaction wasSuccessful:YES];
                // Download is complete. Content file URL is at
                // path referenced by download.contentURL. Move
                // it somewhere safe, unpack it and give the user
                // access to it
                break;
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	NSLog(@"Restore complete!");
	sendPurchaseEvent("productsRestored", "");
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	NSLog(@"Error restoring transactions");
	sendPurchaseEvent("productsRestoredWithErrors", "");
	
}

- (void)dealloc
{
	if(myProduct)
        [myProduct release];
    
	if(productsRequest)
       [productsRequest release];
    
	if(productID)
        [productID release];
    
	[super dealloc];
}

@end

extern "C"
{
	static InAppPurchase* inAppPurchase = nil;
    
	void initInAppPurchase()
    {
    	printf("init inapppurchase --------------------------------------------------- xx\n");
		inAppPurchase = [[InAppPurchase alloc] init];
		[inAppPurchase initInAppPurchase];
	}
	
	void restorePurchases() 
	{
		[inAppPurchase restorePurchases];
	}
    
	bool canPurchase()
    {
		return [inAppPurchase canMakePurchases];
	}
    
	void purchaseProduct(const char *inProductID)
    {
		NSString *productID = [[NSString alloc] initWithUTF8String:inProductID];
		[inAppPurchase purchaseProduct:productID];
	}
    
	void requestProductData(const char *inProductID)
	{
		NSString *productID = [[NSString alloc] initWithUTF8String:inProductID];
		[inAppPurchase requestProductData:productID];
	}
	
	void finishTransactionManually(const char *inTransactionID)
	{
		NSString *transactionID = [[NSString alloc] initWithUTF8String:inTransactionID];
		[inAppPurchase finishTransactionManually:transactionID];
	}
	
	bool getManualTransactionMode()
	{
		return [inAppPurchase manualTransactionMode ];
	}
	void setManualTransactionMode(bool val) {
		[inAppPurchase setManualTransactionMode:val];
	}
	
	void releaseInAppPurchase()
    {
		//[inAppPurchase release];
	}
}
