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
        void releaseInAppPurchase();
        
        char* getTitle(const char *inProductID);
        char* getPrice(const char *inProductID);
        char* getDescription(const char *inProductID);
    }
}

#endif
