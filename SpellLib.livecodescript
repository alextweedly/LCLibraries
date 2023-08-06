script "SpellLib"
-- SpellLib - library for simepl Spell Checking in Livecode.
--Copyright (c) 2020 Alex Tweedly, released under the MIT License.

--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:

--The above copyright notice and this permission notice shall be included in
--all copies or substantial portions of the Software.

--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--THE SOFTWARE.


local sADict, sAUserDict
local sFileName, sDictFileName

constant kVersion = 1.0

function SpellVersion
   return kVersion
end SpellVersion

-- pStr - string to be checked
-- pAll - TRUE to return all errors, otherwise only the first occurrence of each unknown word
--        returned one-per-line. NB in order of occurrence.
-- pWithOffsets - include that character offset for each unknown word :
--            word TAB first char position TAB last char pos
function spellCheck pStr, pAll, pWithOffsets
   local tErrs, tList, t1
   put empty into tErrs
   put quote&"!?,.:;[]{}()£$¢%^&≤≥÷<>=+-…“‘”¡™#∞§¶*•ªº\/" into tList
   put textencode(pStr, "UTF8") into pStr
   repeat for each char tChar in tList
      replace tChar with space in pStr
      wait 0 millisecs with messages
   end repeat
   
   if keys(sADict)="" then spellInit 
   
   local tWordCounter, tKnownErr
   repeat for each word tW in pStr
      add 1 to tWordCounter
      if isNumber( tW) then next repeat
      if NOT (sADict[char 1 of tW][tW] OR sAUserDict[tW]) then
         if pAll then
            -- return ALL errors (including duplicates)
            put tW &CR after tErrs
         else
            if NOT tKnownErr[tW] then
               put TRUE into tKnownErr[tW]
               put tW &CR after tErrs
            end if
         end if
      end if
   end repeat
   if pWithOffsets then
      local tStartAt, tOffset, tResult
      put 0 into tStartAt
      repeat for each line L in tErrs
         put offset(L, pStr, tStartAt) into tOffset
         if tOffset = 0 then
            breakpoint
         end if
         put tStartAt + tOffset into t1
         put L & TAB & t1 &TAB& t1 + the number of chars in L -1 &CR after tResult
         add tOffset + the number of chars in L to tStartAt
      end repeat
      put tResult into tErrs
   end if
   return tErrs
end spellCheck

-- pStr - string to be checked
-- pCharsToSkip - number of chars to skip from the start
function spellCheckIncremental pStr, pCharsToSkip
   local tList, t1
   put quote&"!?,.:;[]{}()£$¢%^&≤≥÷<>=+-…“‘”¡™#∞§¶*•ªº\/" into tList
   put textencode(char (pCharsToSkip+1) to -1 of pStr, "UTF8") into pStr
   repeat for each char tChar in tList
      --      put the millisecs into t1
      replace tChar with space in pStr
      --      put the millisecs - t1 && tChar &CR after msg
      wait 0 millisecs with messages
      --      if the shiftkey is down then exit repeat
   end repeat
   
   if keys(sADict)="" then spellInit
   
   local tOffSet, tResult
   repeat for each word tW in pStr
      if isNumber(tW) then next repeat
      if NOT (sADict[char 1 of tW][tW] OR sAUserDict[tW]) then
         -- return it !!
         put offset(tW, pStr) into tOffset
         if tOffset = 0 then
            breakpoint
         end if
         put pCharsToSkip + tOffset into t1
         --         put t1 + the number of chars in tW -1 into t2
         put tW & TAB & t1 & TAB & t1 + the number of chars in tW -1 into tResult
         return tResult
      end if
   end repeat
   return empty
end spellCheckIncremental

on spellInit
   local tmp, tList, tCompleted
   put specialfolderpath("resources") & "/spellLibDictionary" into sDictFilename
   try
      put URL ("binfile:" & sDictFilename) into tmp
      put arraydecode(tmp) into sADict
      put TRUE into tCompleted
   catch tError
      
   end try
   if NOT tCompleted then
      put specialfolderpath("resources") & "/spellLibDictionary.txt" into sFilename
      local tDict,  tNextStartLetter, tEndLine
      put URL ("file:" & sFilename) into tDict
      sort lines of tDict ascending
      put "',A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z" into tList
      repeat with i=1 to 27
         if i<27 then
            put item i+1 of tList into tNextStartLetter
            put lineOffset(cr&tNextStartLetter,tDict) into tEndLine
            put (line 1 to tEndLine of tDict) into tmp
            split tmp by CR as set
            put tmp into sADict[item i of tList]
            delete line 1 to tEndLine of tDict
         else 
            put tDict into tmp
            split tmp by CR as set
            put tmp into sADict[item i of tList]
         end if
      end repeat
      put arrayencode(sADict) into URL ("binfile:" & sDictFilename) 
   end if
   
   put specialfolderpath("resources") & "/UserDictionary.txt" into sFilename
   put URL ("file:" & sFilename) into tDict
   put tDict into tmp
   split tmp by CR as set
   put tmp into sAUserDict
end spellInit

-- SpellLern : add word pWord to the User dictionary
on spellLearn pWord
   put pWord & CR after URL ("file:" & sFileName)
   put TRUE into sAUserDict[pWord]
end spellLearn

-- SpellReset :  which means next call will re-read/build the dictionary
on SpellReset
   put empty into sADict
   put empty into sAUserDict
end SpellReset
