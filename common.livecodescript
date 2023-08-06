script "Common Utilities"
--> all handlers

-- Common Library
-- intended to be the one and only Common library,
--     combining all functions from all versions
--     BUT excluding textDB
constant kLibraryName = "Common Library"
constant kLibraryVersion = 3.0

function getCommonVersion
   return "top" && kLibraryName && kLibraryVersion
end getCommonVersion

global gDebug, gLibraryPath

command loadLibrary pLib
   local tStacks, tPath
   if gLibraryPath is empty then
     put specialfolderpath("documents") & "/My LiveCode/Libraries" into gLibraryPath
   end if
   put  the stacksinuse  into tStacks
   if pLib = "Server Common Lib" then 
      exit loadLibrary
   end if
   if NOT (tStacks contains pLib) then
      put gLibraryPath & "/" & pLib into tPath
      start using stack (tPath)
   end if
   
end loadLibrary

// Handy utilities

----------------------------------------------------------------------
--| FUNCTION trim
--|
--| Summary: remove leading & trailing whitespace
--|
--| Format:  trim(pString)
--|
--| Parameters: pString
--|
--| Return: trimmed version of <pString>
----------------------------------------------------------------------
function trim pString
   return word 1 to -1 of pString
end trim

----------------------------------------------------------------------
--| FUNCTION Q
--|          wrapQ
--|
--| Summary: wrap quotes around text
--|
--| Format:  Q(pString)
--|          wrapQ(pString)
--|
--| Parameters: pString
--|
--| Return: quoted version of <pString>
----------------------------------------------------------------------
function Q pText
   return quote & pText & quote
end Q
function wrapQ pText
   return quote & pText & quote
end wrapQ

----------------------------------------------------------------------
--| FUNCTION putWithDefault
--|
--| Summary: return either a value, or a default version of it
--| 
--| Format:  putWithDefault(pString, pDefault)
--|
--| Parameters: pString - the string to be used / defaulted
--|                          pDefault - if <pSring> is empty, this is the default to use instead
--|
--| Return: either <pString> or its default <pDefault>
----------------------------------------------------------------------
function putWithDefault pVal, pDefault
   if pVal is not empty then return pVal
   return pDefault
end putWithDefault

----------------------------------------------------------------------
--| FUNCTION todayAsSQL
--|
--| Summary: get current date[time] in SQL format YYYY-MM-DD HH:MM:SS
--|           OR convert date in dateitems format to SQL Format
--|
--| Format:  todayAsSQL(pTime)
--|
--| Parameters: pWithTime - TRUE if the time should be appended
--|             pDateItems - date/time to use instead of 'now'
--|
--| Return: the current date[time] in SQL format YYYY-MM-DD HH:MM:SS
----------------------------------------------------------------------
function todayAsSQL pWithTime, pDateItems
   local tDateOut
   if pDateItems is empty then
      put the long internet date into pDateItems
      convert pDateItems from internet date to dateitems
   end if
   put format("%04d-%02d-%02d", item 1 of pDateItems, item 2 of pDateItems, item 3 of pDateItems) into tDateOut
   if pWithTime then
      put format(" %02d:%02d:%02d", item 4 of pDateItems, item 5 of pDateItems, item 6 of pDateItems) after tDateOut
   end if
   return tDateOut
end todayAsSQL

function SQLAsDateItemsSafe pD
   local temp
   if char 11 to -1 of pD is empty then
      put " 12:00:00" into char 11 to -1 of pD  
   end if
   put SQLAsDateItems(pD) into temp
   return temp
end SQLAsDateItemsSafe


----------------------------------------------------------------------
--| FUNCTION getItem
--|
--| Summary: convenience function to get an item with different itemDelimiter
--| 
--| Format:  getItem(pString, pItemNum, pDelimiter)
--|
--| Parameters: pString - the input string
--|                          pItemNum - number of item desired
--|                          pDelimiter - item delimiter
--|
--| Return: one item frm the string
----------------------------------------------------------------------
function getItem pData, pItemNum, pDelim
   set the itemdel to pDelim
   return item pItemNum of pData
end getItem

----------------------------------------------------------------------
--| FUNCTION exactlyTheSame
--|
--| Summary: return TRUE / FALSE is the paramters are euqal, with casesensitive true
--|
--| Format:  exactlyTheSame(pA,pB)
--|
--| Parameters: pA, pB - the two strings to be compared
--|
--| Return: either True or False
----------------------------------------------------------------------
function exactlyTheSame pA, pB
  set the casesensitive to true
  return pA = pB
end exactlyTheSame

----------------------------------------------------------------------
--| FUNCTION putWithDefault
--|
--| Summary: return either a value, or a default version of it
--|
--| Format:  putWithDefault(pString, pDefault)
--|
--| Parameters: pString - the string to be used / defaulted
--|                          pDefault - if <pSring> is empty, this is the default to use instead
--|
--| Return: either <pString> or its default <pDefault>
----------------------------------------------------------------------
function putWithDefault pVal, pDefault
   if pVal is not empty then return pVal
   return pDefault
end putWithDefault

----------------------------------------------------------------------
--| FUNCTION firstOf
--|
--| Summary: return the value of the first non-empty parameter
--|
--| Format:  firstOf(p1, p2, p3, ...)
--|
--| Parameters: pN - each of the strings to be used
--|
--| Return: one of p1, p2, .. or empty
----------------------------------------------------------------------
function firstOf
   local temp
   repeat with i = 1 to paramcount()
      put param(i) into temp
      if temp is not empty then exit repeat
   end repeat
   return temp
end firstOf

function isEmail pEmail
   local regemail, validate, temp
   
   put "((?i)(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|§(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*§)@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\]))" into regemail 
   replace "§" with quote in regemail #now regemail is the correct regula espression
   put matchtext(pEmail,regemail,validate) into temp
   
   if validate is not pEmail then
      return FALSE
   else
      return TRUE
   end if
end isEmail

----------------------------------------------------------------------
--| FUNCTION md5hash
--|
--| Summary: get the legible Hex version of the md5 hash of a string
--| 
--| Format:  md5hash(pString)
--|
--| Parameters: pString - input string
--|
--| Return: md5has, converted to hex digits
----------------------------------------------------------------------
function md5hash pText
   local tMD5, tHash
   put md5digest(pText) into tMD5
   get binarydecode("H*",tMD5,tHash) 
   return tHash
end md5hash

----------------------------------------------------------------------
--|  COMMAND copyArrayByKey
--|
--| Summary: copies a given set of keyed elements from one array to another
--| 
--| Format:   copyArrayByKey pAFrom, pATo, pKeys
--|
--| Parameters: pAFrom - source array
--|                          pATo - destination array
--|                          pKeys -comma-separated list of keys 
--|
--| Return: pATo modified to contain addition/over-written elements
----------------------------------------------------------------------
command copyArrayByKey @pAFrom, @pATo, pKeys
   repeat for each item I in pKeys
      put pAFrom[I] into pATo[I]
   end repeat
end copyArrayByKey

----------------------------------------------------------------------
--|  COMMAND copyArrayAllKeys
--|
--| Summary: copies all elements from one array to another
--| 
--| Format:   copyArrayAllKey pAFrom, pATo
--|
--| Parameters: pAFrom - source array
--|                          pATo - destination array
--|
--| Return: pATo modified to contain addition/over-written elements
----------------------------------------------------------------------
command copyArrayAllKeys @pAFrom, @pATo
   repeat for each key I in pAFrom
      put pAFrom[I] into pATo[I]
   end repeat
end copyArrayAllKeys

----------------------------------------------------------------------
--|  COMMAND simplifyForURL
--|
--| Summary: Take string, simplify to be suitable for URL
--|           make lower case, remove spaces
--|
--| Format:   simplifyForURL("Arbitrary string")
--|
--| Parameters: pString - string to be simplified
--|
--| Return: pString turned inot lower case, with spaces changed to "_"
----------------------------------------------------------------------
function simplifyForURL pString
   put tolower(pString) into pString
   replace space with "_" in pString
   return pString
end simplifyForURL
--
---- calculate the seconds some time from now
--function secsFromNow pYearsFromNow, pMonthsFromNow, pDaysFromNow, pHoursFromNow
--   local tNow

--   put the seconds into tNow
--   convert tNow to dateItems

--   -- add the number of days/months, then do a double-convert to fix up any weird dates
--   add pYearsFromNow to item 1 of tNow
--   add pMonthsFromNow to item 2 of tNow
--   add pDaysFromNow to item 3 of tNow
--   add pHoursFromNow to item 4 of tNow
--   convert tNow to seconds
--   return tNow
--end secsFromNow
---- date conversion - ? why ?
--function convertDate pDate
--   if char 5 of pDate <> "-" then return pDate
--   if char 8 of pDate <> "-" then return pDate
--   replace "-" with COMMA in pDate
--   put ",0,0,0,0" after pDate
--   --  put "HERE" && pDate & "<br>" & CR
--   convert pDate to  abbreviated date
--   return pDate
--end convertDate

-- Handy routines for output, handling quotes, etc.
global gSomethingOutputAlready --  check for / give warning if you try to output a cookie too late

----------------------------------------------------------------------
--| FUNCTION trim
--|
--| Summary: output a line, with <br> if on a server
--| 
--| Format:  pl pString
--|
--| Parameters: pString
--|
--| Return: none
----------------------------------------------------------------------
command pl pStr
   put true into gSomethingOutputAlready
   if the environment = "server" then
      put pStr & "<br>" & CR
   else
      put pStr & CR after msg
   end if
end pl

----------------------------------------------------------------------
--| COMMAND putCookie
--|
--| Summary: output a cookie
--| 
--| Format:  putCookie pCookie, pValue, pScope, pUntil
--|
--| Parameters: 
--|   pCookie - cookie name
--|   pValue - vlaue for cookie
--|   pScope - scope to be applied to
--|   pUntil - expiration time
--|
--| Return: none
----------------------------------------------------------------------
command putCookie pCookie, pValue, pScope, pUntil
   if gSomethingOutputAlready then
      pl "attempt to set cookie after something already output"
   end if
   if the environment = "server" then
      if pScope is empty then
         put "/" into pScope
      end if
      if pUntil is not empty then
         put cookie pCookie for pScope with pValue until pUntil
      else
         put cookie pCookie for pScope with pValue
      end if
   else
      pl "PUT COOKIE in development mode !!"
   end if
end putCookie

----------------------------------------------------------------------
--| COMMAND printArray
--|
--| Summary: output an array (usually for debugging)
--| 
--| Format:  printArray pName, pArray
--|
--| Parameters: pName - name (or just a helpful string)
--|                          pArray - the array to be displayed
--|
--| Return: none
----------------------------------------------------------------------
command printArray pName, pArray
   if pArray is an array then
      pl pName & " = {"
      dumpArray pArray, " ", " "
      pl "}"
   end if
end printArray

----------------------------------------------------------------------
--| COMMAND dumpArray
--|
--| Summary: output an array in pretty-print format (usually for debugging)
--| 
--| Format:  dumpArray  pArray, pIndent, pIndentString
--|
--| Parameters: 
--|  pArray - the array to be displayed
--|  pIndent - the indent to be used here
--|  pIndentString - the cumulative indent string
--|
--| Return: none
----------------------------------------------------------------------
command dumpArray pArray, pIndent, pIndentString
   local tKeys, tError
   if pArray is an array then
      put the keys of pArray into tKeys
      sort lines of tKeys
      repeat for each line tKey in tKeys
         if pArray[tKey] is an array then
            pl pIndent & tKey & " = {" 
            dumpArray pArray[tKey], (pIndent & pIndentString), pIndentString
            pl pIndent & "}"
         else
            pl pIndent & tKey & " = " & pArray[tKey]
         end if
      end repeat
   end if
end dumpArray

----------------------------------------------------------------------
--| FUNCTION formatArray
--|
--| Summary: return a pretty-print format of an array
--| 
--| Format:  formatarray(pArray, pIndent, pIndentString)
--|
--| Parameters: 
--|  pArray - the array to be displayed
--|  pIndent - the indent to be used here
--|  pIndentString - the cumulative indent string
--|
--| Return: the formatted string
----------------------------------------------------------------------
function formatArray pArray, pIndent, pIndentString
   local tKeys, tError, tResult
   put empty into tResult
   if pArray is an array then
      put the keys of pArray into tKeys
      sort lines of tKeys
      repeat for each line tKey in tKeys
         if pArray[tKey] is an array then
            put pIndent & tKey & " = {" & "<br>" & CR after tResult
            put formatArray(pArray[tKey], (pIndent & pIndentString), pIndentString)  & "<br>" & CR after tResult
            put pIndent & "}"  & "<br>" & CR after tResult
         else
            put pIndent & tKey & " = " & pArray[tKey] & "<br>" & CR after tResult
         end if
      end repeat
   end if
   return tResult
end formatArray


----------------------------------------------------------------------
--| FUNCTION outArray
--|
--| Summary: output array to show changes
--| 
--| Format:  outASrray(pArray)
--|
--| Parameters: pArray - the array 
--|
--| Return: string showing all items in array, with "id" first
----------------------------------------------------------------------
function outArray pAy
   -- function to output a string for an array, e.g. for DB changes
   local tKeys
   put the keys of pAy into tKeys
   sort lines of tKeys
   if "ID" is among the lines of tKeys then
      filter tKeys without "ID"
      put ID &CR before tKeys
   end if
   local tL, tResult
   repeat for each line L in tKeys
      put pAy[L] into tL
      if the number of lines in tL > 1 then
         replace CR with (CR & ":") in tL
         put L &CR& ":" & tL &CR after tResult
      else
         put L & ":" & tL &CR after tResult
      end if
   end repeat
   return tResult
end outArray

--function inArray pText
--   -- function to input a string to an array, e.g. for DB changes
--   local tCurNum, tCurElement
--   set the itemDel to ":"
--   put 0 into tCurNum
--   put "none" into tCurElement

--   local tA
--   repeat for each line L in pText
--      switch
--         case char 1 of L = ":"
--            put char 2 to -1 of L & CR after tA[tCurNum][tCurElement]
--            break
--         case L is empty
--            break
--         default
--            if L contains ":" then
--               if item 1 of L = "ID" then
--                  add 1 to tCurNum
--                  put item 2 to -1 of L into tA[tCurNum]["ID"]
--                  put "none" into tCurElement
--               else
--                  put item 2 to -1 of L into tA[tCurNum][item 1 of L]
--               end if
--               break
--            end if
--            put L into tCurElement
--            put empty into tA[tCurNum][tCurElement]
--            break
--      end switch    
--   end repeat
--   -- printarray "inarray", tA
--   return tA
--end inArray

----------------------------------------------------------------------
--| FUNCTION getParams
--|
--| Summary: consolidate $_GET and $_POST into one array
--| 
--| Format:  getParams())
--|
--| Parameters: 
--|
--| Return: array of all GET/POST parameters
----------------------------------------------------------------------
function  getParams
   local tParams
   repeat for each key K in $_GET
      put $_GET[K] into tParams[K]
   end repeat
   repeat for each key K in $_POST
      put $_POST[K] into tParams[K]
   end repeat
   return tParams
end getParams

----------------------------------------------------------------------
--| FUNCTION decompose1
--|
--| Summary: check whether a string can be decomposed
--| 
--| Format:  decompose1(pString, pSeparator, @p1, @p2)
--|
--| Parameters: 
--|  pString - string to be considered
--|  pSeparator - separator around which the string will be decomposed
--|  @p1, @p2 - the parts before and after the separator
--|
--| Return: TRUE if separator is found - and then also p1, p2 are return values
----------------------------------------------------------------------
function decompose1 pIn, pSep1, @p1, @p2
   local  t1
   put offset(pSep1, pIn) into t1
   if t1 > 0 then
      put char 1 to t1-1 of pIn into p1
      put char (t1+the number of chars in pSep1) to -1 of pIn into p2
      return TRUE
   end if
   return FALSE
end decompose1

----------------------------------------------------------------------
--| FUNCTION decompose2
--|
--| Summary: check whether a string can be decomposed twice
--| 
--| Format:  decompose2(pString, pSep1, pSpe2, @p1, @p2, @p3)
--|
--| Parameters: 
--|  pString - string to be considered
--|  pSep1 - separator around which the string will be decomposed
--|  pSep2 - second separator around which the string will be decomposed
--|  @p1, @p2, @p3 - the parts before, between and after the separator
--|
--| Return: TRUE if separator is found - and then also p1, p2 are return values
----------------------------------------------------------------------
function decompose2 pIn, pSep1, pSep2, @p1, @p2, @p3
   local t1, tIn, t2
   put offset(pSep1, pIn) into t1
   if t1 > 0 then
      put char t1+the number of chars in pSep1 to -1 of pIn into tIn
      put offset(pSep2, tIn) into t2
      if t2 > 0 then
         put char 1 to t1-1 of pIn into p1
         put char 1 to t2-1 of tIn into p2
         put char t2+the number of chars in pSep2 to -1 of tIn into p3
         return TRUE
      end if
   end if
   return FALSE
end decompose2

----------------------------------------------------------------------
--| FUNCTION markdownToHTML
--|
--| Summary: convert Markdown-LITE to HTML 
--| 
--| Format:  markdownToHTML(pMD)
--|
--| Parameters: pMD - markdown-lite string
--|
--| Return: HTML 
----------------------------------------------------------------------
function markdownToHTML pMD
   local tASubstitutions
   local LL, N, p1, p2, p3, p3a, p4, tSize, tAltText, tAQuery, tArray, tPath, tQuote
   put empty into tASubstitutions
   repeat for each line L in pMD
      -- first extract any image specs
      put L into LL
      put 1 into N
      -- LCMS references, as !![shortcode id](shortname)  -- e.g. !![image small 35](alternate text)
      repeat forever
         if decompose2(LL, "!![", "](", p1, p2, p3) then -- p1!![p2](p3
            if decompose1(p3, ")", p3a, p4) then        -- p1!![p2](p3a)p4
               -- now convert p2 and/or p3a into a LCMS reference type
               --               pl "image" && p1 &":"& p2  &":"& p3  &":"& p3a  &":"& p4
               put empty into tASubstitutions[N]
               if word 1 of p2 = "image" then
                  put word 2 of p2 into tSize
                  if word 3 of p2 is a number then
                     lcmsDBWhere "id", word 3 of p2
                  else
                     lcmsDBWhere "shortname", word 3 of p2
                  end if
                  put p3a into tAltText
                  --                 pl "seeking"  &":"& word 3 of p2  &":"& word 1 of p3a  &":"& tAltText
                  put lcmsDBGet("images") into tAQuery
                  --                 printarray "qq", tAQuery
                  if tAQuery["numrows"] = 1 then
                     put lcmsDBRow(1) into tArray
                     -- printarray "image info", tArray
                     if tArray["alt"] is not empty then
                        put tArray["alt"] into tAltText
                     end if
                     put tArray["folder"] & "/" & tSize & "/" & tArray["filename"] into tPath 
                     put "<img src='/" & tPath & "' alt='" & tAltText & "'>" into tASubstitutions[N]
                  end if
               end if
               put p1 & numtochar(N) & p4 into LL
               add 1 to N
               next repeat
            end if
         end if
         exit repeat
      end repeat
      
      local tResult
      
      repeat forever
         if decompose2(LL, "![", "](", p1, p2, p3) then -- p1![p2](p3
            if decompose1(p3, ")", p3a, p4) then        -- p1![p2](p3a)p4
               put "<img src='" & p3a & "' alt='" & p2 & "'>" into tASubstitutions[N]
               put p1 & numtochar(N) & p4 into LL
               add 1 to N
               next repeat
            end if
         end if
         exit repeat
      end repeat
      
      -- and then do any links
      repeat forever
         if decompose2(LL, "[", "](", p1, p2, p3) then
            if decompose1(p3, ")", p3a, p4) then
               put quote into tQuote
               if char 1 of p3a = "'" then put "'" into tQuote
               if char 1 of p3a = tQuote AND char -1 of p3a = tQuote then
                  put char 2 to -2 of p3a into p3a
               end if
               if char -1 of p3a = "*" then
                  put tQuote & " TARGET=" & tQuote & "blank" into char -1 of p3a
               end if
               if char -9 to -1 of p3a = "_NEW_TAB_" then then
                  put tQuote & " TARGET=" & tQuote & "blank" into char -9 to -1 of p3a
               end if
               if p2 = "fb" then
                  put p1 & "<a href='http://facebook.com/" & p3a & "' TARGET='_blank'>" & "<i class='fa fa-facebook'></i>" & "</a>" & p4 into LL
               else
                  put p1 & "<a href=" & tQuote & p3a & tQuote & ">" & p2 & "</a>" & p4 into LL
               end if
               
               
            end if
         end if
         exit repeat
      end repeat
      
      repeat with i = 1 to N
         replace numtochar(i) with tASubstitutions[i] in LL
      end repeat
      if LL is empty then put L into LL
      local W
      if LL is empty then 
         put CR after tResult
      else
         put word 1 of LL into W
         
         if W is not empty then
            replace "#" with empty in W
            if W is empty then 
               put the number of chars in word 1 of LL into N
               --            put format("<H%d>%s</H%d>", N, word 2 to -1 of LL, N) into LL
               put"<H" & N & ">" & word 2 to -1 of LL & "</H" & N & ">" into LL
            end if
         end if
         put LL &CR after tResult
      end if
      --      if NOT (tResult ends with CR) then exit repeat
      --      delete char -1 of tResult
   end repeat
   replace (numtochar(13) & numtochar(10)) with CR in tResult
   replace (CR & CR &CR) with (CR & "<p><br><p>" & CR) in tResult
   replace (CR & CR) with (CR & "<p>") in tResult
   return tResult
end markdownToHTML

----------------------------------------------------------------------
--| COMMAND markdown
--|
--| Summary: convert each element of an array form MDL to HTML
--| 
--| Format:  markdown pArray
--|
--| Parameters: pArray - array of strings, each converted separately
--|
--| Return: none (the array is modified)
----------------------------------------------------------------------
command markdown @pArray  
   repeat for each key K in pArray
      put markdownToHTML(pArray[K]) into pArray[K]
   end repeat
end markdown


--function getDayNamesArray
--   local t1, t2, tA, rA
--  put the short weekdaynames into t1
--  put the weekdaynames into t2
--  -- NB the numbers and names are distinct - so stick them both in one array :-)
--  repeat with i = 1 to 7
--    put line i of t1 into rA[line i of t2]
--    put line i of t2 into rA[line i of t1]
--  end repeat
--  return rA
--end getDayNamesArray

----------------------------------------------------------------------
--| FUNCTION withBRforCR
--|
--| Summary: Add BRs for output on server
--| 
--| Format:  trim(pString)
--|
--| Parameters: pString
--|
--| Return: trimmed version of <pString>
----------------------------------------------------------------------
function withBRforCR pData
   replace CR with "<BR>" & CR in pData
   --  if pData is not empty then 
   --  if char -5 to -1 of pData <> ("<br>"&CR)  then 
   --    put "<br>"&CR after pData
   --  end if	
   --end if
   return pData
end withBRforCR


----------------------------------------------------------------------
--| FUNCTION gOT
--|
--| Summary: convenience function for optional text
--| 
--| Format:  gOT(pPrefix, pString, pSuffix, pNeedBRs)
--|
--| Parameters: 
--|   pPrefix - prefix, output if needed
--|   pString - string determining wither any output is needed
--|   pSuffix - suffix if needed
--|   pNeedBRs - set TRUE to get <br> s after each line
--|
--| Return: empty, or prefix&string&suffix
----------------------------------------------------------------------
function gOT pPrefix, pTest, pSuffix, pNeedBRs
   if pTest = 0 then return empty
   if pTest is empty then return empty
   if pNeedBRs then
      return pPrefix & withBRforCR(pTest) & pSuffix  
   else
      return pPrefix & pTest & pSuffix  
   end if
end gOT

----------------------------------------------------------------------
--| FUNCTION randomSequence
--|
--| Summary: return 1...N in random order
--| 
--| Format:  randomSequence(pNum)
--|
--| Parameters: pNum - number of integers in the sequence
--|
--| Return: lines continaining the integers in random order
----------------------------------------------------------------------
function randomSequence pNum
   local tResult
   repeat with i = 1 to pNum
      put i &CR after tResult
   end repeat 
   sort lines of tResult by random(pNum)
   return tResult
end randomSequence


----------------------------------------------------------------------
--| FUNCTION escapeHTMLChars
--|
--| Summary: 
--| 
--| Format:  escapeHTMLChars(pString)
--|
--| Parameters: pString
--|
--| Return: 
----------------------------------------------------------------------
local sEscapeStrings
function escapeHTMLChars pText
   local tOrig
   if sEscapeStrings is empty then
      put URL ("file:" & the defaultfolder & "/escape_html.txt") into sEscapeStrings
   end if
   put pText into tOrig
   repeat for each line L in sEscapeStrings
      replace char 1 of L with (char 2 to -1 of L) in pText
   end repeat
   return pText
end escapeHTMLChars

----------------------------------------------------------------------
--| FUNCTION unescapeHTMLChars
--|
--| Summary: 
--| 
--| Format:  unescapeHTMLChars(pString)
--|
--| Parameters: pString
--|
--| Return: 
----------------------------------------------------------------------
function unescapeHTMLChars pText
   local tOrig
   if sEscapeStrings is empty then
      put URL ("file:" & the defaultfolder & "/escape_html.txt") into sEscapeStrings
   end if
   put pText into tOrig
   repeat for each line L in sEscapeStrings
      replace char 2 to -1 of L with char 1 of L in pText
   end repeat
   return pText
end unescapeHTMLChars


----------------------------------------------------------------------
--| FUNCTION mail
--|
--| Summary: send an email
--| 
--| Format:  
--|
--| Parameters: 
--|
--| Return: 
----------------------------------------------------------------------
command mail pTo, pSub, pMsg, pFrom, pCc, pBcc, pHtml, pAtts
   local tMsg
   
   -- build the message header, adding the from, to and subject details
   -- we also put any cc addresses in here, but not bcc (bcc addresses hidden)
   put "From:" && pFrom & return & "To:" && pTo & return & "Subject:" && pSub & \
         return into tMsg    if pCc is not empty then
      put "Cc:" && pCc & return after tMsg
   end if
   
   -- if there are any attachments, we must send this email as multipart
   -- with the message body and each attachment forming a part
   -- we do this by specifying the message as multipart and generating a unique boundary
   if pAtts is an array then
      local tBoundary
      put "boundary" & the seconds into tBoundary
      put "MIME-Version: 1.0" & return & "Content-Type: multipart/mixed; boundary=" & \
            wrapQ(tBoundary) & return & "--" & tBoundary & return after tMsg
   end if
   
   -- add the actual message body, setting the content type appropriately
   if pHtml is true then
      put "Content-Type: text/html;" & return & return after tMsg
   else
      put "Content-Type: text/plain;" & return & return after tMsg
   end if
   put pMsg & return after tMsg
   
   -- add each attachment as a new part of the message, separating using 
   -- the generated boundary
   if pAtts is an array then
      put "--" & tBoundary & return after tMsg
      repeat for each element tAtt in pAtts
         if there is a file tAtt["path"] then
            if tAtt["type"] is empty then
               get "application/octet-stream"
            else
               get tAtt["type"]
            end if
            put "Content-Type:" && it & "; name=" & wrapQ(tAtt["name"]) & ";" & \
                  return & "Content-Transfer-Encoding: base64;" & return & return & \
                  base64Encode(URL ("binfile:" & tAtt["path"])) & return & "--" & \
                  tBoundary & return after tMsg
         end if
      end repeat
   end if
   
   -- send the mail by piping the message we have just built to the sendmail command
   -- we must also send a copy of the message to the bcc addresses
   get shell("echo" && wrapQ(shellEscape(tMsg)) && "| /usr/sbin/sendmail" && \
         wrapQ(shellEscape(pTo)) && "-f" && wrapQ(shellEscape(pFrom)))
   if pBcc is not empty then
      get shell("echo" && wrapQ(shellEscape(tMsg)) && "| /usr/sbin/sendmail" && \
            wrapQ(shellEscape(pBcc)) && "-f" && wrapQ(shellEscape(pFrom)))
   end if
   put "MAIL sent" && the seconds & CR & \
         "TO:" && pTo & CR & \
         "SUBJ:" && pSub & CR &CR after URL ("file:./log_mail.txt")
end mail

----------------------------------------------------------------------
--| FUNCTION parseMail
--|
--| Summary: parse an email
--| 
--| Format:  parseMail(pString)
--|
--| Parameters: pString
--|
--| Return: 
----------------------------------------------------------------------

-- handlers for mail parsing
function parseMail pMail
   -- splits the email into the different parts (as an array)
   local K, tA, tCount, t, tStarted
   
   set the itemDel to ":"
   put false into tStarted
   
   repeat for each line L in pMail
      if not tStarted then
         if L begins with "From " then
            put true into tStarted
         end if
         next repeat
      end if
      if char 1 of L = TAB then
         put CR & L after tA[K]
         next repeat
      end if
      if L contains ":" then
         put item 1 of L into K
         if K is among the keys of tA then
            put the keys of tA[K] into t
            replace CR with comma in t
            put max(t) into tCount
            add 1 to tCount
            put item 2 to -1 of L into tA[K][tCount]
         else
            put item 2 to -1 of L into tA[K]
         end if
      else
         put L & CR after tA["body"]
      end if
   end repeat
   return tA
end parseMail

----------------------------------------------------------------------
--| COMMAND setAreaProportional
--|
--| Summary: limit size of image, keeping relative proportions
--| 
--| Format:  setAreaProportional(pImageID, pWidth, pHeight)
--|
--| Parameters: 
--|
--| Return: none
--|         Resizes an image such that both width & height are within
--|         the specified limits; sizing is proportional
----------------------------------------------------------------------
command setAreaProportional pImageID, pWidth, pHeight
   local tProportionalWidth, tProportionalHeight, tRatio
   
   put (the formattedWidth of pImageID) / pWidth into tRatio
   put (the formattedHeight of pImageID) / tRatio into tProportionalHeight
   
   put (the formattedHeight of pImageID) / pHeight into tRatio
   put (the formattedWidth of pImageID) / tRatio into tProportionalWidth
   
   if tProportionalHeight > pHeight then
      lock screen
      set the width of pImageID to tProportionalWidth
      set the height of pImageID to pHeight
      unlock screen
   else
      lock screen
      set the width of pImageID to pWidth
      set the height of pImageID to tProportionalHeight
      unlock screen
   end if
   return tRatio for value
end setAreaProportional

----------------------------------------------------------------------
--| FUNCTION resizeImageFile
--|
--| Summary: resize the image in a file
--| 
--| Format:  resizeImageFile(pFile, pOutFile, pMaxWid, pMaxHeight)
--|
--| Parameters: 
--|        pFile - full path to the input file
--|        pOutFile - full path name of where to create the output file
--|        pMaxWid, pMaxHeight - maximum width/height for the output
--|
--|
--|
--| Return: Nothing. 
--|         Creates the output file with a version of the image resized 
--|         proportionally to be within the max limits specified
----------------------------------------------------------------------
function resizeImageFile pFile, pOutFile, pMaxWid, pMaxHeight
   local t, tt
   
   import paint from file pFile
   put the name of the last image into t
   set the name of t to "Im1"
   
   clone img "Im1"
   set the name of it to "Im2"
   setAreaProportional the long id of img "Im2", pMaxWid, pMaxHeight
   export img "Im2" to file pOutFile as jpeg
   put the result into tt
   
   delete img "Im2"
   delete img "Im1"
   
   return empty      -- "Done resize" & ":" & tt & ":" && pFile && pOutfile
end resizeImageFile

----------------------------------------------------------------------
--| COMMAND appendNumericArrays
--|
--| Summary: append array pA2 after pA1, assuming both are numeric-indexed arrays
--| 
--| Format:  appendNumericArrays pA1, pA2
--|
--| Parameters: 
--|
--| Return: 
----------------------------------------------------------------------
command appendNumericArrays @pA1, pA2
   -- append array pA2 after pA1, assuming both are numeric-indexed arrays
   local tBase, tLen
   local t_local_debug
   --  put TRUE into t_local_debug
   put item 2 of extents(pA1)  into tBase
   put item 2 of extents(pA2)  into tLen
   if tLen > 0 then
      if t_local_debug then
         pl "appending" && tBase && tLen
      end if
      repeat with i = 1 to tLen
         put pA2[i] into pA1[tBase+i]
      end repeat
      if t_local_debug then
         pl "to get" && the keys of pA1
      end if
   end if
end appendNumericArrays


# Produce an array of folders + files with the "full" relative paths
command getArrayOfFiles pFolder, @pA, pIgnoreDotFolders, pIgnoreDotFiles
   local tFiles, tFolders
   local tThisFolder
   if pIgnoreDotFolders is empty then 
      put TRUE into pIgnoreDotFolders
   end if
   if pIgnoreDotFiles is empty then 
      put TRUE into pIgnoreDotFiles
   end if
   
   put the defaultfolder into tThisFolder
   
   local tAbsFolder, tFoldersLeft, tSub
   set the defaultfolder to pFolder
   put the defaultfolder into tAbsFolder   -- changes relative into absolute 
   
   put CR into tFoldersLeft
   repeat until tFoldersLeft is empty
      put line 1 of tFoldersLeft into tSub
      delete line 1 of tFoldersLeft
      set the defaultFolder to (tAbsFolder & tSub) 
      if the result is not empty then
         -- skip or report as needed
         next repeat
      end if
      try
         put folders() into tFolders
      end try
      if pIgnoreDotFolders then
         filter tFolders without ".*"
      else
         filter tFolders without "."
         filter tFolders without ".."
      end if
      repeat for each line L in tFolders
         put tSub & "/" & L & CR after tFoldersLeft
      end repeat
      
      try
         put the detailed files into tFiles
      end try
      
      if pIgnoreDotFiles then
         filter tFiles without ".*"
      end if   
      repeat for each line L in tFiles
         put item 2 to -1 of L into pA[pFolder & tSub][item 1 of L]
      end repeat
   end repeat
   set the defaultfolder to tThisFolder
end getArrayOfFiles

# Produce a nested array of folders + files with the "full" relative paths
function getNestedArrayOfFiles pFolder, pIgnoreDotFolders, pIgnoreDotFiles
   local tFiles, tFolders
   local tA
   if pIgnoreDotFolders is empty then
      put TRUE into pIgnoreDotFolders
   end if
   if pIgnoreDotFiles is empty then
      put TRUE into pIgnoreDotFiles
   end if

   try
      put folders(pFolder) into tFolders
   end try

   if tFolders is not empty then
      if pIgnoreDotFolders then
         filter tFolders without ".*"
      else
         filter tFolders without "."
         filter tFolders without ".."
      end if
      repeat for each line L in tFolders
         put getNestedArrayOfFiles(pFolder & "/" & L, pIgnoreDotFolders, pIgnoreDotFiles) into tA[" " & L]
      end repeat
   end if

   try
      put files(pFolder, "detailed") into tFiles
   end try
   if pIgnoreDotFiles then
      filter tFiles without ".*"
   end if
   repeat for each line L in tFiles
      put item 5 of L into tA[item 1 of L]
   end repeat

   return tA
end getNestedArrayOfFiles


----------------------------------------------------------------------
--| FUNCTION shellEscape
--|
--| Summary: escape shell characters: use this function before passing data to the shell
--| 
--| Format:  shellEscape(pString)
--|
--| Parameters: pString
--|
--| Return: escaped version of <pString>
----------------------------------------------------------------------
function shellEscape pText
-- keep this at the end because it messes up Coda colouring
   repeat for each char tChar in "\`!$" & quote
      replace tChar with "\" & tChar in pText
   end repeat
   return pText
end shellEscape


-- things that would normally be in a common library
command logInfo p
   put p &CR after msg
end logInfo


function combineArrays 
   local tAReturn, tA
   repeat with I = paramcount() down to 1
      put param(i) into tA
      repeat for each key K in tA
         put tA[K] into tAReturn[K]
      end repeat
   end repeat
   return tAReturn
end combineArrays


----------------------------------------------------------------------
--| FUNCTION SQLAsDate
--|
--| Summary: convert an SQL date[time] into long date 
--|    i.e. SQL format YYYY-MM-DD HH:MM:SS --> dayname, Month DD [hh:mm:ss]
--|
--| Format:  SQLAsDate(pTime)
--|
--| Parameters: pDateTime - Date [time] to convert
--|             pShort - if TRUE, return without the day name
--|
--| Return: the date[time] in SQL format converted to long date/time
----------------------------------------------------------------------
function SQLAsDate pDateTime, pShort
   local tDate
   
   if pDateTime is empty then return empty
   
   put (char 6 to 7 of pDateTime & "/" & char 9 to 10 of pDateTime & "/" & char 1 to 4 of pDateTime)  into tDate
   
   convert tDate to long English date
   
   if pShort then
      delete word 1 of tDate
   end if
   return tDate
end SQLAsDate

----------------------------------------------------------------------
--| FUNCTION SQLAsDateItems
--|
--| Summary: convert an SQL date[time] into  dateitems
--|    i.e. SQL format YYYY-MM-DD HH:MM:SS --> yy,mm,dd,hh,mm,ss,0
--|
--| Format:  SQLAsDateItems(pTime)
--|
--| Parameters: pDateTime - Date [time] to convert
--|             
--| Return: the date[time] in SQL format converted to dateitems
----------------------------------------------------------------------
function SQLAsDateItems pDateTime
   local tDate, tTime, tResult
   
   if pDateTime is empty then return empty
   
   put word 1 of pDatetime into tDate
   put word 2 of pDatetime into tTime
   
   set the itemDel to "-"
   put item 1 of tDate & ","  after tResult
   put item 2 of tDate & "," after tResult
   put item 3 of tDate & "," after tResult
   put item 1 of tTime & "," after tResult
   put item 2 of tTime & "," after tResult
   put item 3 of tTime & ",0" after tResult
   return tResult
end SQLAsDateItems

-- Julian Day Number    -- As Per http://fox.wikis.com/wc.dll?Wiki~JulianDates
-- Agrees with Wikipedia January 1, 2000, was 2,451,545.
-- from user forums by Lagi Pittas
--  takes eith yyyy/mm/dd  or dateitems (yyyy,mm,dd,...)
function JDN pDate
   local  lnD, lnM, lnYr, lnJulianDate
   
   if pDate contains "/" then
      set itemdelimiter to "/"
      put item 1 of pDate into lnD
      put item 2 of pDate into lnM
      put item 3 of pDate into lnYr
   else
      set the itemDel to comma
      put item 3 of pDate into lnD
      put item 2 of pDate into lnM
      put item 1 of pDate into lnYr
   end if
   
   put  367  *  lnYr - TRUNC(7 * (lnYr + TRUNC ((lnM + 9) / 12)) / 4) into  lnJulianDate     
   put lnJulianDate  - TRUNC(3 * (TRUNC((lnYr + (lnM - 9) / 7) / 100) + 1) / 4) into lnJulianDate
   
   put  lnJulianDate  + TRUNC(275 * lnM / 9)     +  lnD + 1721029    into lnJulianDate
   
   Return lnJulianDate
end JDN


----------------------------------------------------------------------
--| FUNCTION datetimeOffset
--|
--| Summary: Add days, hours, minutes, seconds to a date in dateitems format
--|
--| Format:  datetimeOffset(pDateItems, tDays, tHours, tMins, tSecs)
--|
--| Parameters: pDateItems - Date & time to add/subtract
--|             pxxx - number of days, hours, minutes, seconds to add(subtract)
--|
--| Return: the modified date and time in dateitems format
----------------------------------------------------------------------
function datetimeOffset pDateItems, pDays, pHours, pMins, pSecs
   repeat with i = 2 to 5
      add param(i) to item (i+1) of pDateItems
   end repeat
   convert pDateItems to dateitems
   return pDateItems
end datetimeOffset


