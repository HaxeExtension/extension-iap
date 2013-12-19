#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h> 
#include "InAppPurchase.h"
#include "InAppPurchaseEvent.h"


extern "C" void sendPurchaseEvent(const char* type, const char* data);
extern "C" void sendPurchaseDownloadEvent(const char* type, const char* productID, const char* transactionID, const char* downloadPath, const char* downloadVersion, const char* downloadProgress);
extern "C" void sendPurchaseProductDataEvent(const char* type, const char* productID, const char* localizedTitle, const char* localizedDescription, const char* price);


@interface InAppPurchase: NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    SKProduct* myProduct;
    SKProductsRequest* productsRequest;
	NSString* productID;
}

- (void)initInAppPurchase;
- (void)restorePurchases;
- (BOOL)canMakePurchases;
- (void)purchaseProduct:(NSString*)productIdentifiers;
- (void)requestProductData:(NSString*)productIdentifiers;
- (void)finishTransactionManually:(NSString *)transactionID;

@end

@implementation InAppPurchase

#pragma Public methods 

- (void)initInAppPurchase 
{
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
		NSLog(@"Can't start another purchase until previous one is complete.");
		return;
	}
	
	productID = productIdentifiers;
	productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productID]];
	productsRequest.delegate = self;
	[productsRequest start];
} 

- (void)requestProductData:(NSString*)productIdentifiers
{
	if(productID) 
	{
        [productID release];
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

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse*)response
{   	
	int count = [response.products count];
    NSLog(@"productsRequest");
	NSLog(@"Number of Products: %i", count);
    
	if(count > 0) 
    {
		if (productID)
		{
			myProduct = [response.products objectAtIndex:0];
			// A payment has been done
			SKPayment *payment = [SKPayment paymentWithProductIdentifier:productID];
			[[SKPaymentQueue defaultQueue] addPayment:payment];
		}
		else
		{
			// A products data request has been responded
			
			for(SKProduct *prod in response.products)
			{
				sendPurchaseProductDataEvent("productData", [prod.productIdentifier UTF8String], [prod.localizedTitle UTF8String], [prod.localizedDescription UTF8String], [[prod.price stringValue] UTF8String]);

			}
			
			sendPurchaseEvent("productDataComplete", nil);
						
		}
	} 
    
    else 
    {
		NSLog(@"No products are available");
	}
    
    [productsRequest release];
    productsRequest = NULL;
}

- (void)finishTransactionManually:(NSString *)transactionID
{
	if ([[SKPaymentQueue defaultQueue] transactions]) {
		NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
		
		if ([transactions containsObject:transactionID]) {
			[self finishTransaction:[transactions objectAtIndex:[transactions indexOfObject:transactionID]]  wasSuccessful:YES];
		}
		
		[transactions release];
	}
}

- (void)finishTransaction:(SKPaymentTransaction*)transaction wasSuccessful:(BOOL)wasSuccessful
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if(wasSuccessful)
    {
    	NSLog(@"Successful Purchase");
		sendPurchaseEvent("success", [transaction.payment.productIdentifier UTF8String]);
    }
    
    else
    {
    	NSLog(@"Failed Purchase");
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

- (void)restoreTransaction:(SKPaymentTransaction*)transaction
{
	NSLog(@"Restoring Transaction");
	sendPurchaseEvent("restore", [transaction.payment.productIdentifier UTF8String]);
    [self finishTransaction:transaction wasSuccessful:YES];
} 

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
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
                
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
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	NSLog(@"Error restoring transactions");
	
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
	
	void releaseInAppPurchase()
    {
		[inAppPurchase release];
	}
}
