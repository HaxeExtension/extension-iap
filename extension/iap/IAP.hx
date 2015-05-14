package extension.iap;

typedef IAProduct = extension.iap.TIAProduct;

#if ios

typedef IAP = extension.iap.ios.IAP;

#elseif android

typedef IAP = extension.iap.android.IAP;

#else

typedef IAP = extension.iap.fallback.IAP;

#end
