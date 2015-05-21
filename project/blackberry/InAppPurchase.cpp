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

namespace iap {

	char groupName[256];
	unsigned waitingEventProductId;

	void log(const char *msg) {
		FILE *logFile = fopen("logs/log.txt", "a");
		fprintf(logFile, "%s\n", msg);
		fclose(logFile);
	}

	void initInAppPurchase() {

		// Reset log file
		FILE *logFile = fopen("logs/log.txt", "w");
		fclose(logFile);

		bps_initialize();

		// https://github.com/blackberry/SDL/blob/emulate/src/video/playbook/SDL_playbookvideo.c#L561
		snprintf(groupName, 256, "SDL-window-%d", getpid());

		log(groupName);

		paymentservice_request_events(0);

		/*
		* Set the Payment Service connection mode to local. This allows us to
		* test the API without the need to contact the AppWorld nor payment servers.
		*/
		paymentservice_set_connection_mode(true);

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

	void requestProductData(const char *productID, ProductData *pData) {

		log("requestProductData call - start");

		unsigned price;
		paymentservice_get_price(productID, NULL, groupName, &price);

		/*
		char strPrice[64];
		snprintf(strPrice, 64, "%d milibarios", price);
		sendPurchaseProductDataEvent(
			"product_data",
			productID,
			"<title>",
			"<description>",
			price,
			strPrice,
			"<Mbr>"
		);
		*/
		pData->id = productID;
		pData->price = price;

		log("requestProductData call - end");

	}

	void queryInventory() {

		log("queryInventory call - start");

		paymentservice_get_existing_purchases_request(true, groupName, &waitingEventProductId);

		log("queryInventory call - end");

	}

	void finishTransactionManually(const char *transactionID) {

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

		sendPurchaseEvent("purchase_sucess", digital_good);

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

	void pollEvent() {

		bps_event_t *event = NULL;
		bps_get_event(&event, -1);

		if (event==NULL) {
			return;
		}

		if (bps_event_get_domain(event) == paymentservice_get_domain()) {
			
			log("recibio evento de compras");
			unsigned request_id = paymentservice_event_get_request_id(event);
			if (request_id!=waitingEventProductId) {
				log("No era");
				return;
			}
			char test[64];
			snprintf(test, 64, "llego evento codigo %d\n", request_id);
			log(test);

			if (SUCCESS_RESPONSE == paymentservice_event_get_response_code(event)) {
				if (PURCHASE_RESPONSE == bps_event_get_code(event)) {
					// Handle a successful purchase here
					onPurchaseSuccess(event);
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
