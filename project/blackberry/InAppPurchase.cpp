#include <bps/bps.h>
#include <bps/navigator.h>
#include <bps/paymentservice.h>
#include <pthread.h>
#include <screen/screen.h>
#include <stdio.h>
#include <stdlib.h>

#include "InAppPurchase.h"

extern "C" void sendPurchaseEvent(const char* type, const char* data);

extern "C" void sendPurchaseProductDataEvent(
	const char* type,
	const char* productID,
	const char* localizedTitle,
	const char* localizedDescription,
	int priceAmountMicros,
	const char* localizedPrice,
	const char* priceCurrencyCode
);

extern "C" void sendPurchaseInventoryData(
	const char* type,
	iap::InventoryEntry *inventoryEntries,
	int inventoryLength
);

extern "C" void sendPurchaseFinishEvent(
	const char* type,
	const char* productID,
	const char* transactionID,
	double transactionDate,
	const char* receipt
);

namespace iap {

	char groupName[256];
	unsigned waitingEventProductId;

	void log(const char *msg) {
		/*
		FILE *logFile = fopen("logs/log.txt", "a");
		fprintf(logFile, "%s\n", msg);
		fclose(logFile);
		*/
	}

	void initInAppPurchase(bool local) {

		// Reset log file
		/*
		FILE *logFile = fopen("logs/log.txt", "w");
		fclose(logFile);
		*/

		bps_initialize();

		// https://github.com/blackberry/SDL/blob/emulate/src/video/playbook/SDL_playbookvideo.c#L561
		snprintf(groupName, 256, "SDL-window-%d", getpid());

		log(groupName);

		paymentservice_request_events(0);

		/*
		* Set the Payment Service connection mode to local. This allows us to
		* test the API without the need to contact the AppWorld nor payment servers.
		*/
		paymentservice_set_connection_mode(local);

	}

	void restorePurchases() {

	}

	bool canPurchase() {

	}

	void purchaseProduct(const char* productID) {

		log("purchaseProduct call");

		char logStr[256];

		if (paymentservice_purchase_request(
			productID,  // digital_good_id
			NULL,       // digital_good_sku
			NULL,       // digital_good_name
			NULL,       // metadata
			NULL,       // app_name
			NULL,       // app_icon
			groupName,  // group_id
			&waitingEventProductId
		) != BPS_SUCCESS ) {
			log("Error: purchase request failed.");
		}

		snprintf(logStr, 256, "post comprar: %d", waitingEventProductId);
		log(logStr);

	}

	void requestProductData(const char *productID) {

		log("requestProductData call - start");

		unsigned price;
		paymentservice_get_price(productID, NULL, groupName, &waitingEventProductId);

		log("requestProductData call - end");

	}

	void queryInventory() {

		log("queryInventory call - start");

		paymentservice_get_existing_purchases_request(true, groupName, &waitingEventProductId);

		log("queryInventory call - end");

	}

	bool finishTransactionManually(const char *transactionID) {
		return false;
	}

	bool getManualTransactionMode() {

	}

	void setManualTransactionMode(bool val) {

	}

	void releaseInAppPurchase() {

	}

	void onFailureCommon(bps_event_t *event) {

		if (event == NULL) {
			fprintf(stderr, "Invalid event.\n");
			return;
		}

		int error_id = paymentservice_event_get_error_id(event);
		const char* error_text = paymentservice_event_get_error_text(event);

		sendPurchaseEvent("failure", error_text);

	}

	void onPurchaseSuccess(bps_event_t *event) {

		if (event == NULL) {
			fprintf(stderr, "Invalid event.\n");
			return;
		}

		const char* date = paymentservice_event_get_date(event, 0);
		const char* digital_good = paymentservice_event_get_digital_good_id(event, 0);
		const char* digital_sku = paymentservice_event_get_digital_good_sku(event, 0);
		const char* license_key = paymentservice_event_get_license_key(event, 0);
		const char* metadata = paymentservice_event_get_metadata(event, 0);
		const char* purchase_id = paymentservice_event_get_purchase_id(event, 0);

		sendPurchaseFinishEvent("purchase_sucess", digital_good, purchase_id, atof(date), NULL);

	}

	void onGetExistingPurchasesSuccess(bps_event_t *event) {

		if (event == NULL) {
			fprintf(stderr, "Invalid event.\n");
			return;
		}

		int purchases = paymentservice_event_get_number_purchases(event);
		InventoryEntry purchases_detail[purchases];

		int i = 0;
		for (i = 0; i<purchases; i++) {
			purchases_detail[i].date = paymentservice_event_get_date(event, i);
			purchases_detail[i].digital_good = paymentservice_event_get_digital_good_id(event, i);
			purchases_detail[i].digital_sku = paymentservice_event_get_digital_good_sku(event, i);
			purchases_detail[i].license_key = paymentservice_event_get_license_key(event, i);
			purchases_detail[i].metadata = paymentservice_event_get_metadata(event, i);
			purchases_detail[i].purchase_id = paymentservice_event_get_purchase_id(event, i);
		}

		log("pre send inventory_sucess");
		sendPurchaseInventoryData("inventory_sucess", purchases_detail, purchases);
		log("post send inventory_sucess");

	}

	void onGetPriceSucess(bps_event_t *event) {

		if (event == NULL) {
			fprintf(stderr, "Invalid event.\n");
			return;
		}

		const char *str_price = paymentservice_event_get_price(event);
		const char* digital_good = paymentservice_event_get_digital_good_id(event, 0);
		sendPurchaseProductDataEvent(
			"product_data",
			digital_good,
			"",						//const char* localizedTitle,
			"",						//const char* localizedDescription,
			0,						//int priceAmountMicros,
			str_price,				//const char* localizedPrice,
			"U$SDSSA"				//const char* priceCurrencyCode
		);

	}

	void pollEvent() {

		bps_event_t *event = NULL;
		bps_get_event(&event, -1);

		if (event==NULL) {
			return;
		}

		if (bps_event_get_domain(event) == paymentservice_get_domain()) {

			unsigned request_id = paymentservice_event_get_request_id(event);
			if (request_id!=waitingEventProductId) {
				return;
			}
			char test[64];
			snprintf(test, 64, "llego evento codigo %d\n", request_id);
			log(test);

			if (SUCCESS_RESPONSE == paymentservice_event_get_response_code(event)) {
				unsigned bps_code = bps_event_get_code(event);
				if (PURCHASE_RESPONSE == bps_code) {
					// Handle a successful purchase here
					onPurchaseSuccess(event);
				} else if (GET_PRICE_RESPONSE == bps_code) {
					onGetPriceSucess(event);
				} else {
					// Handle a successful query for past purchases here
					log("query response");
					onGetExistingPurchasesSuccess(event);
					log("post query response");
				}
			} else {
				onFailureCommon(event);
			}

		}

	}

}
