#ifndef IN_APP_PURCHASE_H
#define IN_APP_PURCHASE_H

namespace iap
{

	#ifdef BLACKBERRY

	typedef struct {
		const char* date;
		const char* digital_good;
		const char* digital_sku;
		const char* license_key;
		const char* metadata;
		const char* purchase_id;
	} InventoryEntry;

	#endif

	#ifndef BLACKBERRY
	extern "C"
	{
	#endif
		bool canPurchase();
		bool getManualTransactionMode();
		void finishTransactionManually(const char *transactionID);
		void initInAppPurchase();
		void purchaseProduct(const char* productID);
		void releaseInAppPurchase();
		void requestProductData(const char *productID);
		void restorePurchases();
		void setManualTransactionMode(bool val);
		#ifdef BLACKBERRY
		void pollEvent();
		void queryInventory();
		#endif
	#ifndef BLACKBERRY
	}
	#endif

}

#endif
