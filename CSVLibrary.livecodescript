script "CSVLibrary"

/**
CSVToTab convert a comma delimited data file to TAB delimited
*/
function CSVToTab pData, pOldLineDelim, pOldItemDelim, pNewCR, pNewTAB
   -- fill in defaults
   if pOldLineDelim is empty then put CR into pOldLineDelim
   if pOldItemDelim is empty then put COMMA into pOldItemDelim
   if pNewCR is empty then put numtochar(11) into pNewCR   -- Use <VT> for quoted CRs
   if pNewTAB is empty then put numtochar(29) into pNewTAB      -- Use <GS> (group separator) for quoted TABs
   
   local tNuData                         -- contains tabbed copy of data
   
   local tStatus, theInsideStringSoFar
   
   -- Normalize line endings: REMOVED 
   -- Will normaly be correct already, only binfile: or similar chould make this necessary
   -- and that exceptional case should be the caller's responsibility
   
   put "outside" into tStatus
   set the itemdel to quote
   repeat for each item k in pData
      -- put tStatus && k & CR after msg
      switch tStatus
         
         case "inside"
            put k after theInsideStringSoFar
            put "passedquote" into tStatus
            next repeat
            
         case "passedquote"
            -- decide if it was a duplicated escapedQuote or a  closing quote
            if k is empty then   -- it's a duplicated quote
               put quote after theInsideStringSoFar
               put "inside" into tStatus
               next repeat
            end if
            -- not empty - so we remain inside the cell, though we have left the quoted section
            -- NB this allows for quoted sub-strings within the  cell content !!
            replace pOldLineDelim with pNewCR in theInsideStringSoFar
            replace TAB with pNewTAB in theInsideStringSoFar
            put theInsideStringSoFar after tNuData
            
         case "outside"
            replace pOldItemDelim with TAB in k
            -- and deal with the "empty trailing item" issue in  Livecode
            replace (pNewTAB & pOldLineDelim) with pNewTAB & pNewTAB & CR in k
            put k after tNuData
            put "inside" into tStatus
            put empty into theInsideStringSoFar
            next repeat
         default
            put "defaulted"
            break
      end switch
   end repeat
   
   -- and finally deal with the trailing item isse in input data
   -- i.e. the very last char is a quote, so there is no trigger to flush the 
   --      last item
   if the last char of pData = quote then
      replace pOldLineDelim with pNewCR in theInsideStringSoFar
      replace TAB with pNewTAB in theInsideStringSoFar
      put theInsideStringSoFar after tNuData
   end if
   
   return tNuData
end CSVToTab

/**
- convert text to array (numeric indexed)

*/
function csvTextToArray pText, pHeaders
   local tResultA, N
   if pHeaders is empty then
      put line 1 of pText into pHeaders
      delete line 1 of pText
   end if
   set the itemDel to TAB
   repeat for each line L in pText
      add 1 to N
      repeat with I = 1 to the number of items in L
         put item I of L into tResultA[N][item I of pHeaders]
      end repeat
   end repeat
   return tResultA
end csvTextToArray
   
   
   /**
   - convert array (possibly numeric indexed) to text 
   */
   function csvTabToArray pTabbedDataA, pHeaders, pIndexed, pOutputHeaders
   local tResult
   if pOutputHeaders then
      put pHeaders &CR after tResult
   end if
   if pIndexed then
      repeat with I = 1 to word 2 of line 1 of the extents of pTabbedDataA
         put _outoneline(pTabbedDataA[I]) after tResult
      end repeat
   else
      repeat for each key K in pTabbedDataA
         put _outoneline(pTabbedDataA[K], pHeaders) after tResult
      end repeat
   end if
   return tResult
end csvTabToArray

private function _outoneline pA, pHeaders, pItemDelim, pLineDelim
   local tResult
   if pItemDelim is empty then put TAB into pItemDelim
   if pLineDelim is empty then put CR into pLineDelim
   if pHeaders is empty then
      -- no headers - we need to guess
      if the extents of pA is not empty then
         repeat with I = 1 to word 2 of line 1 of the extents of pA
            put pA[I] & pItemDelim after tResult
         end repeat
      else
         local tKeys
         put the keys of pA into tKeys
         sort lines of tKeys  -- need to do every one in the same order, as best we can
         repeat for each line L in tKeys
            put pA[L] & pItemDelim after tResult
         end repeat
      end if
   else
      repeat for each item ITM in pHeaders
         put pA[ITM] & pItemDelim after tResult
      end repeat
   end if
   return tResult & pLineDelim
end _outoneline
