#ifndef IN_APP_PURCHASE_H
#define IN_APP_PURCHASE_H

namespace iap
{
	extern "C"
	{
		bool canPurchase();
		bool getManualTransactionMode();
		bool finishTransactionManually(const char *transactionID);
		void initInAppPurchase(const char* dbgData);
		void checkQueue();
		const char* getReceipt();
		void purchaseProduct(const char* productID, const char* loginID);
		void releaseInAppPurchase();
		void requestProductData(const char *productID);
		void restorePurchases();
		void setManualTransactionMode(bool val);
	}
}
#endif
