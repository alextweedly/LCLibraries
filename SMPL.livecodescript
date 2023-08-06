script "SMPL"
/**
smplFileToArray

*/
function smplFileToArray pFilename
   local tData, tKey, tAResult, tSoFar
   local tArrayKey, tArrayIndex
   local tLineNumber
   
      put URL ("file:" & pFilename & ".smpl") into tData
      put smplToArray(tLineNumber, tData, empty) into tAResult
      
      if tAResult is an array then
         return tAResult
      end if
   return empty
end smplFileToArray

/**
   - reads one section of a SMPL file (perhaps recursively)
*/
function smplToArray @pLineNumber, pText, pExitName
   -- NB pLineNumber is the number of lines BEORE the first one we look at
   local tData, tKey, tAResult, tSoFar
   local tArrayKey, tArrayIndex
   
   local tNumberOfLines
   put the number of lines in pText into tNumberOfLines
   local tFirstWord, L, tmp
   repeat  forever
      add 1 to pLineNumber
      if pLineNumber > tNumberOfLines then exit repeat
      put line pLineNumber of pText into L
      put word 1 of L into tFirstWord
      if tFirstWord begins with "--" OR tFirstWord is empty then
         next repeat
      end if
      if tFirstWord = "-" then  -- a significant '-'
         delete word 1 of L
         add 1 to tArrayIndex
         put word 1 of L into tFirstWord
      end if
      --      if tFirstWord begins with "-" then  -- it *must* be a significant '-'
      --         delete char 1 of tFirstWord
      --         add 1 to tArrayIndex
      --         if tFirstWord = ":" then next repeat
      --      end if
      local tValue, tMatchingEnd
      if tFirstWord ends with ":" then
         put _smplUnEscape(char 1 to -2 of tFirstWord) into tKey
         
         if char 1 of word 2 of L = "?" then
            -- so it IS a simple value starting with a special character
            put word 2 to -1 of L into tValue
            delete char 1 of tValue
            -- and remove trailing '?', e.g. to keep trailing whitespace in final value
            delete char -1 of tValue
            
         else if word 2 of L = "[" then
            -- it's start of a new (sub-) array section
            put smplToArray(pLineNumber, pText, tKey) into tValue
            
         else if word 2 of L = "]" then
            if tKey is empty OR tKey = pExitName then
               return tAResult
            else
               breakpoint -- shouldn't happen !
            end if
            
         else if word 2 of L = "|" then --  a multi-line value
            put word 3 of L into tMatchingEnd
            put _smplReadMultiLineValue(pLineNumber, pText, tMatchingEnd, FALSE) into tValue
            
         else if word 2 of L = ">" then --  a multi-line value, folded
            put word 3 of L into tMatchingEnd
            put _smplReadMultiLineValue(pLineNumber, pText, tMatchingEnd, TRUE) into tValue
            
         else if char 1 of word 2 of L is among the items of "[,],|,>" then --  
            breakpoint -- should not happen - special char not an entire word !!
            next repeat
         else
            -- so it IS a simple value, NO special character
            put word 2 to -1 of L into tValue
         end if
         
         if tArrayIndex < 1 then
            put tValue into tAResult[tKey]
         else
            put tValue into tAResult[tArrayIndex][tKey]
         end if 
      else
         -- not a key: value, not a comment - ????
         breakpoint
      end if
   end repeat
   
   return tAResult
   
end smplToArray

function _smplReadMultiLineValue @pLineNumber, pText, pMatchingEnd, pFolding
   -- NB folding not yet implemented !!
   local tResult, L, tFirstWord
   repeat forever
      add 1 to pLineNumber
      if pLineNumber > the number of lines in pText then
         return tResult
      end if
      put line pLineNumber of pText into L
      put word 1 of L into tFirstWord
      if pMatchingEnd is not empty then
         if pMatchingEnd = tFirstWord then
            return tResult
         end if
         put L &CR after tResult
         next repeat
      end if
      if tFirstWord begins with "?" then
         delete char 1 of tFirstWord
         delete char -1 of tFirstWord
      end if
      if tFirstWord ends with ":" then
         return tResult
      end if
      put L & CR after tResult
   end repeat
   breakpoint
end _smplReadMultiLineValue
   
/**
arrayToSmplFile

*/
function arrayToSmplFile pDataA, pFilename
   local tData, tKey, tAResult, tValue
   
   put arrayToSMPL(pDataA) into tData
   put tData into URL ("file:" & pFilename & ".smpl")
   return empty
end arrayToSmplFile

constant kSpaces = "                                        "

/**
arrayToSPL - convert an array to a SMPL-formatted text string
pDataA - the array to format
pValuesToEncode - the name of the keys whose values houl be base64encoedcomma separated list
NOT YET IMPLEMENTED pKeysToEncodeA - the name of the keys where the *key* should be encoded
NOT YET IMPLEMENTED       NB an array where the keys are the keys, and values are TRUE
pIndent - the number of scpaes indent required, in the range 0-40
pIncrementIndent - number of additional spaces for each array level
*/
function arrayToSMPL pDataA, pValuesToEncode, pKeysToEncodeA, pIndent, pIncrementIndent
   local tData, tKeys, tAResult, tValue, tExtents
   
   if pIndent is empty then put 0 into pIndent
   if pIncrementIndent is empty then put 4 into pIncrementIndent
   
   --   put the keys of pDataA into tKeys
   repeat for each key K in pDataA
      put _smplEscape(K) &CR after tKeys -- i.e. beware CRs in key
   end repeat
   sort lines of tKeys numeric
   
   local tLineCount, tStartOfIndexedSection
   put 0 into tLineCount
   put infinity into tStartOfIndexedSection
   repeat for each line K in tKeys
      add 1 to tLineCount
      if K = 1 then
         if the last line of tKeys = the number of lines in tKeys - tLineCount + 1 then
            -- the trailing numeric lines are suitable to be an indexed array
            put tLineCount into tStartOfIndexedSection
            exit repeat
         end if
      end if
   end repeat
   
   -- NB if you have non-indexed keys as well as indexed ones, then
   --   the non-indexed ones MUST come first, and will do because
   --   of the 'numeric' sort above.
   local tNeedToHaveTerminator, tKey, tIndentation
   local tOriginalKey
   put 0 into tLineCount
   put char 1 to pIndent of kSpaces into tIndentation
   repeat for each line K in tKeys
      put _smplUnEscape(K) into tOriginalKey
      add 1 to tLineCount
      put word 1 of K into tKey
      
      if pDataA[tOriginalKey] is an array then
         if tLineCount < tStartOfIndexedSection then
            put tIndentation & tKey & ":"  & " [" & CR after tData
            put arrayToSMPL(pDataA[tOriginalKey], pValuesToEncode, pKeysToEncodeA,\
                  pIndent+pIncrementIndent, pIncrementIndent) after tData
            put tIndentation & tKey & ":" & "]" & CR after tData
         else
            local tmp
            put arrayToSMPL(pDataA[tOriginalKey], pValuesToEncode, pKeysToEncodeA,\
                  pIndent+pIncrementIndent, pIncrementIndent) into tmp
            put char 3 to -1 of (char 1 to pIndent+pIncrementIndent of kSpaces & "- ") after tData
            delete char 1 to pIndent+pIncrementIndent of tmp
            put tmp after tData
         end if
         next repeat
      end if
      
      put pDataA[tOriginalKey] into tValue
      if the number of lines in tValue > 1 then
         put FALSE into tNeedToHaveTerminator
         repeat for each line L in tValue
            if word 1 of L ends with ":" then
               put TRUE into tNeedToHaveTerminator
               exit repeat
            end if
         end repeat
         -- and make sure we finish with a CR
         if the last char of tValue <> CR then 
            put CR after tValue
         end if
         
         if tNeedToHaveTerminator then
            put uuid() into tNeedToHaveTerminator
            put tIndentation & tKey & ":" & \
                  " | " & tNeedToHaveTerminator & CR & tValue after tData
            put tNeedToHaveTerminator &CR after tData
         else
            put tIndentation & tKey & ":" & " |" & CR & tValue after tData
         end if
         
      else
         if tValue <> trim(tValue) OR char 1 of tValue is among the items of "?,[,],|,>" then
            put "?" before tValue
            put "?" after tValue
         end if
         put tIndentation & tKey & ":" & " " & tValue &CR after tData
      end if
   end repeat
   return tData
end arrayToSMPL

/**
  _smplEscape - encodes the escape sequences within a string, suitable for key output
*/
function _smplEscape pString
   local tOut
   repeat for each char c in pString
      switch c
         --         case "-"
         --            put "\-" after tOut
         --            break
         case quote
            put "\q" after tOut
            break
         case "\"
            put "\\" after tOut
            break
         case CR
            put "\n" after tOut
            break
         case tab
            put "\t" after tOut
            break
         case space
            put "\s" after tOut
            break
         default
            put c after tOut
      end switch
   end repeat
   return tOut
end _smplEscape

/**
   _smplUnescape
*/
function _smplUnEscape pString
   local tOut, tWasBackSlash
   repeat for each char c in pString
      if tWasBackSlash then
         switch c
            --            case "-"
            --               put "-" after tOut
            --               break
            case "q"
               put quote after tOut
               break
               --            case "\"
               --               put "\" after tOut
               --               break
            case "n"
               put CR after tOut
               break
            case "t"
               put TAB after tOut
               break
            case "s"
               put SPACE after tOut
               break
            default
               put c after tOut
         end switch
         put FALSE into tWasBackSlash
      else
         if c = "\" then
            put TRUE into tWasBackSlash
         else 
            put c after tOut
         end if
      end if
   end repeat
   return tOut
end _smplUnEscape
