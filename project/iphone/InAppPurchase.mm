#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h> 
#include "InAppPurchase.h"
#include "InAppPurchaseEvent.h"


extern "C" void sendPurchaseEvent(const char* type, const char* data);
extern "C" void sendPurchaseFinishEvent(const char* type, const char* productID, const char* transactionID, double transactionDate, const char* receipt);
extern "C" void sendPurchaseDownloadEvent(const char* type, const char* productID, const char* transactionID, const char* downloadPath, const char* downloadVersion, const char* downloadProgress);
extern "C" void sendPurchaseProductDataEvent(const char* type, const char* productID, const char* localizedTitle, const char* localizedDescription, int priceAmountMicros, const char* localizedPrice, const char* priceCurrencyCode, const char* priceCountryCode);

void sendPurchaseEventWrap(const char* type, NSString* data)
{
	dispatch_async(dispatch_get_main_queue(), ^{
  		sendPurchaseEvent(type, [data UTF8String]);
	});
}

void sendPurchaseFinishEventWrap(const char* type, NSString* productID, NSString* transactionID, double transactionDate, NSString* receipt)
{
	dispatch_async(dispatch_get_main_queue(), ^{

  		sendPurchaseFinishEvent(type, [productID UTF8String], [transactionID UTF8String], transactionDate, [receipt UTF8String]);
	});
}

void sendPurchaseProductDataEventWrap(const char* type, NSString* productID, NSString* localizedTitle, NSString* localizedDescription, int priceAmountMicros, NSString* localizedPrice, NSString* priceCurrencyCode, NSString* priceCountryCode)
{
	dispatch_async(dispatch_get_main_queue(), ^{
  		sendPurchaseProductDataEvent(type, [productID UTF8String], [localizedTitle UTF8String], [localizedDescription UTF8String], priceAmountMicros, [localizedPrice UTF8String], [priceCurrencyCode UTF8String], [priceCountryCode UTF8String]);
	});
}

@interface InAppPurchase: NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    SKProductsRequest* productsRequest;
	NSArray* products;
	bool manualTransactionMode;
    bool inited;
	bool preInited;
}

- (void)initInAppPurchase;
- (void)restorePurchases;
- (BOOL)canMakePurchases;
- (void)purchaseProduct:(NSString*)productIdentifiers;
- (void)requestProductData:(NSString*)productIdentifiers;
- (BOOL)finishTransactionManually:(NSString *)transactionID;
- (SKProduct*)findProduct:(NSString*)productIdentifier;

@property bool manualTransactionMode;
@property bool inited;
@property (nonatomic, copy) NSString* dbgData;
@end

@implementation InAppPurchase
@synthesize manualTransactionMode;
@synthesize inited;
@synthesize dbgData;

#pragma Public methods 

- (void)initInAppPurchase 
{
	if(!preInited)
	{
		preInited = true;
		static dispatch_once_t onceToken;
		manualTransactionMode = true;
		NSLog(@"xxxxxxx purchase init v2");
		//dispatch_once(&onceToken, ^{
			[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
		//});
	}
    
	NSUInteger nbTransaction = [[SKPaymentQueue defaultQueue].transactions count];
	if (nbTransaction > 0) {
		[self updateAllTransactionsManually];
	}
	sendPurchaseEventWrap("started", @"");
    
    //[self checkQueue];
    //inited = true;
    //[self updateAllTransactionsManually];
}

- (void)checkQueue
{
    NSLog(@"checkQueue");
    
	[self paymentQueue:[SKPaymentQueue defaultQueue] updatedTransactions:[[SKPaymentQueue defaultQueue] transactions]];
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
	SKProduct* product = [self findProduct:productIdentifiers];//findProduct(productIdentifiers);
	if (product != nil)
	{
		NSLog(@"product found");
		SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        	payment.quantity = 1;
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	}
	else
	{
		NSLog(@"product not found");
	}
} 

- (void)requestProductData:(NSString*)productIdentifiers
{
	if(productsRequest != NULL)
	{
		NSLog(@"Can't request product data while performing a previous transaction.");
		return;
	}

	NSSet *productIdentifiersSet = [NSSet setWithArray:[productIdentifiers componentsSeparatedByString:@","] ];
    	productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiersSet];
    	productsRequest.delegate = self;
    	[productsRequest start];
    
    // we will release the request object in the delegate callback
}

- (SKProduct*)findProduct:(NSString*)productIdentifier
{
	for (SKProduct *prod in products)
	{
		if ([prod.productIdentifier isEqualToString:productIdentifier])
		{
			return prod;
		}
	}
	return nil;
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods 

- (void)request:(SKProductsRequest *)request didFailWithError:(NSError *)error
{
	NSLog(@"Error: %@",error);
	if( productsRequest == request ) productsRequest = NULL;
	
	sendPurchaseEventWrap("productDataFailed", error.localizedDescription);
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse*)response
{   	
	int count = [response.products count];
    	NSLog(@"productsRequest");
	NSLog(@"Number of Products: %i", count);

	// release the products request BEFORE calling the completion to support calling purchase()
	// in the completion result handlers
	//[productsRequest release];
	productsRequest = NULL;
    
	if(count > 0) 
	{
		products =  [[NSArray alloc] initWithArray:response.products];

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
			NSString *priceCountryCode = [prod.priceLocale objectForKey:NSLocaleCountryCode];
			
			int priceAmountMicros = [[prod.price decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] intValue];

			sendPurchaseProductDataEventWrap("productData", prod.productIdentifier, prod.localizedTitle, prod.localizedDescription, priceAmountMicros, formattedPrice, priceCurrencyCode, priceCountryCode);

		}
		//[self updateAllTransactionsManually];
		//inited = true;

		sendPurchaseEventWrap("productDataComplete", @"");
	} 
    
    else 
    {
		NSLog(@"No products are available");
	}
}

- (BOOL) finishTransactionManually:(NSString *)transactionID
{
    NSArray * transactions = [[SKPaymentQueue defaultQueue] transactions];
    if (manualTransactionMode && transactions) {
        // 'transactions' contains SKPaymentTransaction, find the appropriate transaction
        for (SKPaymentTransaction * transaction in transactions) {
            if ([transaction.transactionIdentifier isEqualToString:transactionID]) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                return true;
            }
        }

        // transaction identifier was not found, quick developer log and return failure
        NSLog(@"Failed to complete transaction manually. [expected_transaction=%@; open_transactions=%@]", transactionID, [[transactions valueForKey:@"transactionIdentifier"] componentsJoinedByString:@", "]);
    }
    return false;
}

- (void)finishTransaction:(SKPaymentTransaction*)transaction wasSuccessful:(BOOL)wasSuccessful
{
    if(wasSuccessful)
    {
        /*if (!inited)
        {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }*/

        @try {
            NSLog(@"Successful Purchase");
            NSString* receiptString = [[NSString alloc] initWithString:transaction.payment.productIdentifier];

            NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
            if(receiptURL==NULL)
            {
                return;
            }
            
            NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
            if(receipt==NULL)
            {
                return;
            }
            
            NSString *jsonObjectString = [receipt base64EncodedStringWithOptions:0];
            if(jsonObjectString==NULL)
            {
                return;
            }

            jsonObjectString=[jsonObjectString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
            jsonObjectString=[jsonObjectString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            jsonObjectString=[jsonObjectString stringByReplacingOccurrencesOfString:@"\r" withString:@""];

            sendPurchaseFinishEvent("success", [transaction.payment.productIdentifier UTF8String], [transaction.transactionIdentifier UTF8String], ([transaction.transactionDate timeIntervalSince1970] * 1000), [jsonObjectString UTF8String]);
		}
		@catch (NSException *exception) {
			NSLog(@"%@", exception.reason);
		}
	}
    
    else
    {
    	NSLog(@"Failed Purchase");

        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        if (transaction.error.code != SKErrorPaymentCancelled)
        {
            NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
        }
        /* Pass error message instead of transaction.payment.productIdentifier */
        sendPurchaseEventWrap("failed", transaction.error.localizedDescription);
    }
}

- (void)completeTransaction:(SKPaymentTransaction*)transaction
{

	if (transaction.downloads && transaction.downloads.count > 0) {
		sendPurchaseDownloadEvent("downloadStart", [transaction.payment.productIdentifier UTF8String], [transaction.transactionIdentifier UTF8String], nil, nil, nil);
		[[SKPaymentQueue defaultQueue] startDownloads:transaction.downloads];
		
	} else {
		NSLog(@"Finish Transaction");
		[self finishTransaction:transaction wasSuccessful:YES];
	}
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
    	sendPurchaseEventWrap("cancel", transaction.payment.productIdentifier);
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

- (void) updateAllTransactionsManually
{
    NSArray * transactions = [[SKPaymentQueue defaultQueue] transactions];
    NSLog(@"manual updatedTransactions count %lu", (unsigned long)[transactions count]);
    
    for(SKPaymentTransaction *transaction in transactions)
    {
        switch(transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
		NSLog(@"SKPaymentTransactionStatePurchased");
                [self completeTransaction:transaction];
		break;

            case SKPaymentTransactionStateRestored:
		NSLog(@"SKPaymentTransactionStateRestored");
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
		NSLog(@"SKPaymentTransactionStateFailed");
                [self failedTransaction:transaction];
                break;
                
            /*case SKPaymentTransactionStateRestored:
             [self restoreTransaction:transaction];
             break;
             */
			 /*case SKPaymentTransactionStatePurchasing:
                [self purchasingTransaction:transaction];
                break;
			*/
            default:
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray*)transactions
{
	NSLog(@"auto updatedTransactions");
	[self updateAllTransactionsManually];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray*)downloads
{
    for (SKDownload *download in downloads)
    {
        switch (download.downloadState) {
            case SKDownloadStateActive:
                NSLog(@"Download progress = %f and Download time: %f", download.progress, download.timeRemaining);
				
				//sendPurchaseDownloadEvent("downloadProgress", [download.contentIdentifier UTF8String], [download.transaction.transactionIdentifier UTF8String], [[download.contentURL absoluteString] UTF8String], [download.contentVersion UTF8String], [[NSString stringWithFormat:@"%f", download.progress] UTF8String]);
				
                break;
            case SKDownloadStateFinished:
                NSLog(@"Download complete: %@",download.contentURL);
				
				//sendPurchaseDownloadEvent("downloadComplete", [download.contentIdentifier UTF8String], [download.transaction.transactionIdentifier UTF8String], [[download.contentURL absoluteString] UTF8String], [download.contentVersion UTF8String], nil);
				
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
	sendPurchaseEventWrap("productsRestored", @"");
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	NSLog(@"Error restoring transactions");
	sendPurchaseEventWrap("productsRestoredWithErrors", @"");
	
}

- (void)dealloc
{
    NSLog(@"dealloc inapppurchase");
    
	if(products)
        [products release];
    
	if(productsRequest)
       [productsRequest release];

	[super dealloc];
}

@end

extern "C"
{
	static InAppPurchase* inAppPurchase = [[InAppPurchase alloc] init];
    
	void initInAppPurchase(const char *dbgData)
    {
    	printf("init inapppurchase --------------------------------------------------- xx\n");
	
		inAppPurchase.dbgData = [[NSString alloc] initWithUTF8String:dbgData];
		
		[inAppPurchase initInAppPurchase];
	}
	
	void checkQueue()
    {
    	printf("checkQueue inapppurchase --------------------------------------------------- xx\n");
		[inAppPurchase checkQueue];
	}
	
	void restorePurchases() 
	{
		[inAppPurchase restorePurchases];
	}
    
	bool canPurchase()
    {
		return [inAppPurchase canMakePurchases];
	}
	
	const char* getReceipt()
    {
		NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];

        if(!receipt)
            return "";
        else
            return [[receipt base64EncodedStringWithOptions:0] UTF8String];
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
	
	bool finishTransactionManually(const char *inTransactionID)
	{
		NSString *transactionID = [[NSString alloc] initWithUTF8String:inTransactionID];
		return [inAppPurchase finishTransactionManually:transactionID];
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
