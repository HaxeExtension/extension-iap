#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFI.h>
#include <stdio.h>
#include "InAppPurchase.h"
#include "InAppPurchaseEvent.h"


using namespace iap;


AutoGCRoot* purchaseEventHandle = 0;


static value iap_set_event_handle(value onEvent)
{
	purchaseEventHandle = new AutoGCRoot(onEvent);
	return alloc_null();
}
DEFINE_PRIM(iap_set_event_handle, 1);


static value iap_initialize() 
{
	#ifdef IPHONE
	initInAppPurchase();
	#endif
	return alloc_null();
}
DEFINE_PRIM (iap_initialize, 0);


static value iap_restore() 
{
	#ifdef IPHONE
	restorePurchases();
	#endif
	return alloc_null();
}
DEFINE_PRIM (iap_restore, 0);


static value iap_buy(value productID)
{
	#ifdef IPHONE
	purchaseProduct(val_string(productID));
	#endif
	return alloc_null();
}
DEFINE_PRIM(iap_buy, 1);


static value iap_title(value productID)
{
	#ifdef IPHONE
	return alloc_string(getTitle(val_string(productID)));
	#else
	return alloc_null();
	#endif
}
DEFINE_PRIM(iap_title, 1);


static value iap_desc(value productID)
{
	#ifdef IPHONE
	return alloc_string(getDescription(val_string(productID)));
	#else
	return alloc_null();
	#endif
}
DEFINE_PRIM(iap_desc, 1);


static value iap_price(value productID)
{
	#ifdef IPHONE
	return alloc_string(getPrice(val_string(productID)));
	#else
	return alloc_null();
	#endif
}
DEFINE_PRIM(iap_price, 1);


static value iap_canbuy() 
{
	#ifdef IPHONE
	return alloc_bool(canPurchase());
	#else
	return alloc_bool(false);
	#endif
}
DEFINE_PRIM (iap_canbuy, 0);


static value iap_release() 
{
	#ifdef IPHONE
	releaseInAppPurchase();
	#endif
	return alloc_null();
}
DEFINE_PRIM (iap_release, 0);



extern "C" void iap_main() 
{
	val_int(0); // Fix Neko init
}
DEFINE_ENTRY_POINT(iap_main);



extern "C" int iap_register_prims() { return 0; }



extern "C" void sendPurchaseEvent(const char* type, const char* data)
{
    value o = alloc_empty_object();
    alloc_field(o,val_id("type"),alloc_string(type));
    alloc_field(o,val_id("data"),alloc_string(data));
    val_call1(purchaseEventHandle->get(), o);
}