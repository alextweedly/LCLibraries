script "yaml"

/**
Summary: Converts a YAML file to an array.

pFilename: Path to YAML file.

Description:
Converts a YAML file to an array. You must use the same spacing throughout the file for indentation.

Note that there are some limitations with regards to YAML that is supported:
1. Comments are not supported.
2. - is not supported

Example:
put yamlFileToArray(tFilename) into tYamlA
put the keys of tYamlA

Returns:
the result: Error message
it: Array

License: yaml.livecodescript is released under the MIT license. 
It was originally developed by Trevor Devore as part of the Levure framework,
And uses code developed by Monte Goulding (see comments below).
I (Alex Tweedly) simply extracted it from the framework and put in separate file for
easier distributin and use outside the entire Levure framework.
*/
function yamlFileToArray pFilename
  local tError, tYaml

  put readFileContents(pFilename) into tYaml
  put the result into tError

  if tError is empty then
    YAMLToArray textDecode(tYaml, "utf8")
    if the result is empty then
      return it for value
    else
      return the result for error
    end if
  else
    return tError for error
  end if
end yamlFileToArray


private function readFileContents pFilename
  local tError

  open file pFilename for read
  put the result into tError

  if tError is empty then
    read from file pFilename until eof
    if the result is not "eof" then
      put the result into tError
    end if

    close file pFilename
  end if

  if tError is empty then
    return it for value
  else
    return tError && "(" & pFilename & ")" for error
  end if
end readFileContents


private function _printArray pArray, pDimension, pFullData
  local tKeys, tKey, tText

  if pDimension is empty then put 0 into pDimension

  put the keys of pArray into tKeys
  sort tKeys numeric

  repeat for each line tKey in tKeys
    if pArray[tKey] is an array then
      put _printCharXTimes(space, pDimension * 3) & tKey & cr after tText
      put _printArray(pArray[tKey], pDimension + 1, pFullData) after tText
    else
      if pFullData then
        put _printCharXTimes(space, pDimension * 3) &  tKey & ":" && pArray[tKey] & cr after tText
      else
        put _printCharXTimes(space, pDimension * 3) &  tKey & ":" && line 1 of pArray[tKey] & cr after tText
      end if
    end if
  end repeat

  return tText
end _printArray


private function _printCharXTimes pChar, pTimes
  local tStr

  repeat with i = 1 to pTimes
    put pChar after tStr
  end repeat
  return tStr
end _printCharXTimes


## Monte's YAMLToArray command
constant kMultiLineModeNone = 0
constant kMultiLineModeLiteral = 1
constant kMultiLineModeFolded = 2

command YAMLToArray pYaml
   local tInDocument = true
   local tPath
   local tArray
   local tPathLists
   local tReferences
   local tMultiLineMode
   local tCharNo
   
   put kMultiLineModeNone into tMultiLineMode
   
   local tMultiLine
   repeat for each line tLine in pYaml
      -- ignore directives
      if tLine begins with "%" then
         next repeat
      end if
      
      if tLine begins with "---" then
         put true into tInDocument
         next repeat
      end if
      
      if not tInDocument then
         next repeat
      end if
      if tLine begins with "..." then
         if tMultiLineMode is not kMultiLineModeNone then
            __ClearQuotes tMultiLine
            put tMultiLine into tArray[tPath]
            put kMultiLineModeNone into tMultiLineMode
         end if
         put false into tInDocument
         next repeat
      end if
      local tPathElement, tListItem
      put __PathElement(tLine, tListItem, tPathLists) into tPathElement
      -- comment lines
      put __unquotedCharOffset("#", tLine) into tCharNo
      if tCharNo > 0 then
         delete char tCharNo to -1 of tLine
      end if
      -- remain in multiline until indent is lower
      if tMultiLineMode is not kMultiLineModeNone then
         if tPathElement < the number of elements of tPath + 1 and tLine is not empty then
            __ClearQuotes tMultiLine
            put tMultiLine into tArray[tPath]
            put kMultiLineModeNone into tMultiLineMode
         else
            -- add back any stripped literal indents
            if tPathElement > the number of elements of tPath + 1 then
               repeat for tPathElement - (the number of elements of tPath + 1)
                  put "    " before tLine
               end repeat
            end if
            
            -- empty lines and indented lines are literal even in folded mode
            if tMultiLineMode is kMultiLineModeLiteral then
               if tMultiLine is not empty then
                  put return after tMultiLine
               end if
               put tLine after tMultiLine
            else
               if tLine is empty then
                  put return after tMultiLine
               else if char 1 of tLine is space or \
                     the last line of tMultiLine is empty or \
                     the last line of tMultiLine begins with space then
                  if tMultiLine is not empty then
                     put return after tMultiLine
                  end if
                  put tLine after tMultiLine
               else
                  if tMultiLine is not empty then
                     put space after tMultiLine
                  end if
                  put tLine after tMultiLine
               end if
            end if
            
            next repeat
         end if
      end if
      
      -- empty lines
      if tLine is empty then
         next repeat
      end if
      
      local tElements
      put the number of elements of tPath into tElements
      if tPathLists[tPathElement] and \
            tListItem and \
            tPath[tPathElement] is an integer then
         add 1 to tPath[tPathElement]
         repeat with tIndex = tElements down to tPathElement + 1
            delete variable tPath[tIndex]
            delete variable tPathLists[tIndex]
         end repeat
         add 1 to tPathElement
      else
         if tPathElement < tElements then
            repeat with tIndex = tElements down to tPathElement + 1
               delete variable tPath[tIndex]
               delete variable tPathLists[tIndex]
            end repeat
         else if tPathElement > tElements + 1 then
            return "invalid YAML" for error
         end if
         
         put tListItem into tPathLists[tPathElement]
         if tListItem then
            put 1 into tPath[tPathElement]
            add 1 to tPathElement
         end if
      end if
      
      -- handle line with just list marker
      if the number of words of tLine is 0 then
         next repeat
      end if
      
      -- map
      put __unquotedCharOffset(":", tLine) into tCharNo
      if tCharNo > 0 then
         local tKey
         
         put char 1 to tCharNo-1 of tLine into tKey
         put char tCharNo+1 to -1 of tLine into tLine
         __ClearQuotes tKey
         
         if tKey is empty then
            return "invalid YAML" for error
         end if
         
         put false into tPathLists[tPathElement]
         put tKey into tPath[tPathElement]
         
         -- clean whitespace
         put word 1 to -1 of tLine into tLine
         
         -- referenced element
         local tRef
         if tLine begins with "&" then
            put word 1 of tLine into tRef
            put "*" into char 1 of tRef
            delete word 1 of tLine
         else
            put empty into tRef
         end if
         
         -- check for referenced element
         if tLine is not empty and word 1 of tLine is among the keys of tReferences then
            put tArray[tReferences[word 1 of tLine]] into tLine
         end if
         
         -- store referenced element
         if tRef is not empty then
            put tPath into tReferences[tRef]
         end if
         
         -- ignore explicit typing
         if tLine begins with "!" then
            delete word 1 of tLine
         end if
         
         if tLine is "|" then
            put kMultiLineModeLiteral into tMultiLineMode
            put empty into tMultiLine
         else if tLine is ">" then
            put kMultiLineModeFolded into tMultiLineMode
            put empty into tMultiLine
         else
            __AddToArray tLine, tArray[tPath]
         end if
      else
         __AddToArray tLine, tArray[tPath]
      end if
   end repeat
   
   if tMultiLineMode is not kMultiLineModeNone then
      __ClearQuotes tMultiLine
      put tMultiLine into tArray[tPath]
   end if
   
   return tArray for value
end YAMLToArray


private function __unquotedCharOffset pChar, pLine
  local tOffset = 0
  local tCharOffset
  local tInQuote = "false"

  repeat for each char tChar in pLine
    add 1 to tOffset
    if tChar is quote then
      put not tInQuote into tInQuote
    else if tChar is pChar and not tInQuote then
      return tOffset
    end if
  end repeat

  return 0
end __unquotedCharOffset


private command __AddToArray pLine, @xElement
   local tElements, tKey
   -- trim whitespace
   if pLine is not an array then
      put word 1 to -1 of pLine into pLine
      if pLine begins with "[" and pLine ends with "]" then
         -- support single line flow sequence
         put char 2 to -2 of pLine into pLine
         split pLine by comma
         put the number of elements of pLine into tElements
         repeat with tIndex = 1 to tElements
            put word 1 to -1 of pLine[tIndex] into pLine[tIndex]
            __ClearQuotes pLine[tIndex]
         end repeat
      else if pLine begins with "{" and pLine ends with "}" then
         -- support single line flow sequence
         put char 2 to -2 of pLine into pLine
         split pLine by comma
         set the itemDelimiter to ":"

         local tLine
         put the number of elements of pLine into tElements
         repeat with tIndex = 1 to tElements
            put word 1 to -1 of pLine[tIndex] into pLine[tIndex]

            local tValue
            put item 1 of pLine[tIndex] into tKey
            __ClearQuotes tKey
            put item 2 to -1 of pLine[tIndex] into tValue
            __ClearQuotes tValue

            put tValue into tLine[tKey]
         end repeat
         put tLine into pLine
      else
         __ClearQuotes pLine
      end if
   end if

   put pLine into xElement
end __AddToArray

private command __ClearQuotes @xLine
   if xLine begins with quote and xLine ends with quote then
      put format( char 2 to -2 of xLine) into xLine
   else if xLine begins with "'" and xLine ends with "'" then
      put char 2 to -2 of xLine into xLine
   end if
end __ClearQuotes

private function __PathElement @xLine, @rListItem, pPathLists
   local tPathElement = 1

   put false into rListItem
   repeat
      if xLine begins with "  " then
         add 1 to tPathElement
      else if xLine begins with "- " then
         -- list
         put true into rListItem
      else
         return tPathElement
      end if
      delete char 1 to 2 of xLine
   end repeat
end __PathElement
