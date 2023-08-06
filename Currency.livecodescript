script "Currency"
/* *****************************************************************************
* Geolocation Currency API
* ****************************************************************************/

/* The URL for the geo location API. */
constant kGeoLocationApiUrl = "https://ipwhois.app/json/"

/* List of allowed currency code. */
constant kAllowedCurrencyCodes = "USD,EUR,GBP,AUD"

/* Default currency code. */
constant kDefaultCurrencyCode = "USD"

/* The suggested currency code based on the currenct location. */
local sSuggestedCurrencyCode

/* The currently selected currency code. */
local sSelectedCurrencyCode

/**
* Returns the currency code in use by the current user. 
*
* @return Currency code, one of GBP, USD, EUR or AUD
*/
function currencyGetCode
   if sSuggestedCurrencyCode is empty then
      if the platform is "web" then
         wait 1 milliseconds with messages
      end if
      
      /* If we've not previously fetched a suggested currency code, then do so by 
      * calling the geo location API via a GET URL request. The API will return,
      * among other thinds, a suggested currency for the current IP address.*/
      local tResponse
      put URL kGeoLocationApiUrl into tResponse
                  
      if the result is empty then
         /* The response retunred by the API is expected to be JSON encoded, 
         * attempt to decode to a LiveCode array. If this fails, an exception will
         * be thrown. In this case, we can just ignore any error and instead 
         * default to USD. */
         try
            put JsonImport(tResponse) into tResponse
            put tResponse["currency_code"] into sSuggestedCurrencyCode
         end try
      end if
      
      /* If have no currency code, or the currency code suggested is not valid,
      * then use a defailt value.*/
      if sSuggestedCurrencyCode is not among the items of kAllowedCurrencyCodes then
         put kDefaultCurrencyCode into sSuggestedCurrencyCode
      end if
   end if
   
   /* If no currency code has been selected then use the suggested value. */
   if sSelectedCurrencyCode is empty then
      put sSuggestedCurrencyCode into sSelectedCurrencyCode
   end if
   
   return sSelectedCurrencyCode
end currencyGetCode

/**
* Returns the currency symbol in use by the current user.
*
* @return Currency symbol
*/
function currencyGetSymbol
   switch currencyGetCode()
      case "USD"
         return "$"
      case "EUR"
         return "€"
      case "GBP"
         return "£"
      case "AUD"
         return "$"
   end switch
end currencyGetSymbol

/**
* Set the currency code for the current user.
*
* @param pCurrencyCode Currency code, one of GBP, EUR, USD or AUD
*/
command currencySetCode pCurrencyCode
   put pCurrencyCode into sSelectedCurrencyCode
end currencySetCode


