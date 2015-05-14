#include <bps/bps.h>
#include <bps/navigator.h>
#include <bps/paymentservice.h>
#include <screen/screen.h>
#include <stdio.h>
#include <stdlib.h>

namespace iap {

	void log(const char *msg) {
		FILE *logFile = fopen("tmp/log.txt", "a");
		fprintf(logFile, "%s\n", msg);
		fclose(logFile);
	}

	char groupName[256];

	void initInAppPurchase() {

		// Reset log file
		FILE *logFile = fopen("tmp/log.txt", "w");
		fclose(logFile);

		// https://github.com/blackberry/SDL/blob/emulate/src/video/playbook/SDL_playbookvideo.c#L561
		snprintf(groupName, 256, "SDL-window-%d", getpid());

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

		char logStr[256];
		unsigned requestId;	// The Payment Service populates this parameter upon successful completion.

		if (paymentservice_purchase_request(
			productID,	// digital_good_id
			NULL,		// digital_good_sku
			NULL,		// digital_good_name
			NULL,		// metadata
			NULL,		// app_name
			NULL,		// app_icon
			groupName,	// group_id
			&requestId
		) != BPS_SUCCESS ) {
			log("Error: purchase request failed.");
		}

		snprintf(logStr, 256, "post comprar: %d", requestId);
		log(logStr);

	}

	void requestProductData(const char *productID) {

	}

	void finishTransactionManually(const char *transactionID) {

	}

	bool getManualTransactionMode() {

	}

	void setManualTransactionMode(bool val) {

	}

	void releaseInAppPurchase() {

	}

	void pollEvent() {

		bps_event_t *event = NULL;
		bps_get_event(&event, 0);

		if (event==NULL) {
			return;
		}

		log("recibio evento de compras");

		if (bps_event_get_domain(event) == paymentservice_get_domain()) {
			if (SUCCESS_RESPONSE == paymentservice_event_get_response_code(event)) {
				if (PURCHASE_RESPONSE == bps_event_get_code(event)) {
					log("compra ok");
					unsigned request_id = 0;
					if (paymentservice_get_existing_purchases_request(false, groupName, &request_id) != BPS_SUCCESS) {
						fprintf(stderr, "Error: get existing purchases failed.\n");
					}
				} else {
					log("fallo compra");
				}
			} else {
				log("failure common (?)");
			}
		}

	}

}
