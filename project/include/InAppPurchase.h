#ifndef IN_APP_PURCHASE_H
#define IN_APP_PURCHASE_H

namespace iap 
{	
    extern "C"
    {	
        void initInAppPurchase();
        void restorePurchases();
        bool canPurchase();
        void purchaseProduct(const char* productID);
		void requestProductData(const char *productID);
        void releaseInAppPurchase();
        
        //char* getTitle(const char *inProductID); //the title from the app store doesnt need to match the title used in the app itself.
        //char* getPrice(const char *inProductID); //the price is displayed in the pop up window, but if you need to know before hand there are other ways such as server backed information that matcheds iTunes/Google.
        //char* getDescription(const char *inProductID); //the description also doesnt need to match the description in the app itself.
    }
}

#endif
