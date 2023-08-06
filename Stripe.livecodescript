script "Stripe"
/* *****************************************************************************
* Stripe API
* ****************************************************************************/

/* The current status of any card details fetch that is in progress. */
local sFetchCardDetailsStatus

/* The result of the last card details fetch, either a source token or an error. */
local sFetchCardDetailsResult

/**
* Attemp to get a Stripe token for user card details. This will display an overlay
* allowing the user to enter their card.
*
* Returns a token wrapping a card on success, emnpty if cancelled or an error string
* otherwise.
*
* @return A token wrapping a card on success, empty on abort and a string on error.
*/
function stripeFetchCardDetails
   put empty into sFetchCardDetailsStatus
   put empty into sFetchCardDetailsResult
   
   if the platform is "web" then  
      /* To get user card details, we need to use Stripe's JS API. First of all we need
      * to set the callback handlers that will be invoked by the JS.*/
      local tPreviousJsHandlers
      put the cJavascriptHandlers of this stack into tPreviousJsHandlers      
      set the cJavascriptHandlers of this stack to \
            tPreviousJsHandlers & return & \
            "stripeFetchCardDetailsOnSuccess" & return &\
            "stripeFetchCardDetailsOnCancel" & return & \
            "stripeFetchCardDetailsOnError"      
      
      /* Now call the JS function that will display the card details input. This will
      * be overlayed on top of our LiveCode app.*/
      do "displayFetchCardDetails()" as "javascript"
      
      /* When the card details fetching operation is completed, a callback will be
      * invoked via the JS, so block until the callback has been received.*/
      wait while sFetchCardDetailsStatus is empty with messages
      
      /* We're done with JS now, so restore any previous callback handlers. */
      set the cJavascriptHandlers of this stack to tPreviousJsHandlers
      
      /* Process the result. */
      switch sFetchCardDetailsStatus
         case "success"
            return sFetchCardDetailsResult for value
         case "cancelled"
            return empty for value
         case "error"
            return sFetchCardDetailsResult for error          
      end switch     
   else      
      /* Create a temporary browser widget in which we will execute the Stripe JS API. */ 
      create invisible widget "Browser" as "com.livecode.widget.browser" in this card
      set the rect of widget "Browser" to the rect of this card
      
      /* Setup our callback handlers that will be invoked via JS when the fetch is complete. */
      set the javascriptHandlers of widget "Browser" to \
            "stripeFetchCardDetailsOnSuccess" & return &\
            "stripeFetchCardDetailsOnCancel" & return & \
            "stripeFetchCardDetailsOnError"
      
      /* Start executing the fetch process which is performed via JS in our template html file. */
      local tTemplateHtmlPath
      set the itemDel to slash
      put item 1 to -2 of the effective filename of me & slash & "template.html" \
            into tTemplateHtmlPath
      set the itemDel to comma
      set the htmlText of widget "Browser" to URL ("file:" & tTemplateHtmlPath)
      set the visible of widget "Browser" to true
      
      /* When the card details fetching operation is completed, a callback will be
      * invoked via the JS, so block until the callback has been received.*/
      wait while sFetchCardDetailsStatus is empty with messages
      
      /* We're done with the browser now so we're safe to remove. */
      delete widget "Browser"
      
      /* Process the result. */
      switch sFetchCardDetailsStatus
         case "success"
            return sFetchCardDetailsResult for value
         case "cancelled"
            return empty for value
         case "error"
            return sFetchCardDetailsResult for error          
      end switch     
   end if
end stripeFetchCardDetails

on stripeFetchCardDetailsOnSuccess pSource
   put pSource into sFetchCardDetailsResult
   put "success" into sFetchCardDetailsStatus
end stripeFetchCardDetailsOnSuccess

on stripeFetchCardDetailsOnCancel
   put empty into sFetchCardDetailsResult
   put "cancelled" into sFetchCardDetailsStatus
end stripeFetchCardDetailsOnCancel

on stripeFetchCardDetailsOnError pError
   put pError into sFetchCardDetailsResult    
   put "error" into sFetchCardDetailsStatus
end stripeFetchCardDetailsOnError

