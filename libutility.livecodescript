script "libutility"

/*******************************************************************************
 *
 *  SEQUENCE OPERATIONS
 *
 ******************************************************************************/

function seqMake
	local tSeq
	repeat with i = 1 to the paramCount
		seqPushOntoBack tSeq, param(i)
	end repeat
	return tSeq
end seqMake

command seqPushOntoBack \
		@xSeq, \
		pValue

	put pValue into xSeq[the number of elements in xSeq + 1]
end seqPushOntoBack

command seqPushOntoFront \
		@xSeq, \
		pValue

	repeat with i = the number of elements in xSeq down to 1
		put xSeq[i] into xSeq[i + 1]
	end repeat
	put pValue into xSeq[1]
end seqPushOntoFront

command seqPopFromBack \
		@xSeq

	delete variable xSeq[the number of elements in xSeq]
end seqPopFromBack

command seqPopFromBackInto \
		@xSeq, \
		@rElement

	put xSeq[the number of elements in xSeq] into rElement
	delete variable xSeq[the number of elements in xSeq]
end seqPopFromBackInto

command seqPopFromFront \
		@xSeq

	seqPopFromIndex xSeq, 1
end seqPopFromFront

command seqPopFromFrontInto \
		@xSeq, \
		@rElement

	put xSeq[1] into rElement
	repeat with i = 2 to the number of elements in xSeq
		put xSeq[i] into xSeq[i - 1]
	end repeat
	delete variable xSeq[the number of elements in xSeq]
end seqPopFromFrontInto

command seqPopFromIndex \
		@xSeq, \
		pIndex

	if pIndex <= 0 or pIndex > seqCount(xSeq) then
		throw "sequence index" && pIndex && "out of range"
	end if

	if pIndex is seqCount(xSeq) then
		seqPopFromBack xSeq
		exit seqPopFromIndex
	end if

	repeat with i = pIndex + 1 to the number of elements in xSeq
		put xSeq[i] into xSeq[i - 1]
	end repeat
	delete variable xSeq[the number of elements in xSeq]
end seqPopFromIndex

command seqPopFromIndexInto \
		@xSeq, \
		pIndex, \
		@rElement

	put xSeq[pIndex] into rElement
	seqPopFromIndex xSeq, pIndex
end seqPopFromIndexInto

function seqJoin \
		pLeft, \
		pRight

	seqAppend pLeft, pRight
	return pLeft
end seqJoin

command seqAppend \
		@xSeq, \
		pOther

	repeat for each element tElement in pOther
		seqPushOntoBack xSeq, tElement
	end repeat
end seqAppend

function seqLast \
		pSeq

	return pSeq[the number of elements in pSeq]
end seqLast

function isSeq \
		pSeq

	return pSeq is an array and \
			item 2 of extents(pSeq) is the number of elements in pSeq
end isSeq

function seqCount \
		pSeq

	return the number of elements in pSeq
end seqCount

function seqIndex \
		pSeq, \
		pValue

	repeat with x = 1 to the number of elements in pSeq
		if pSeq[x] is pValue then return x
	end repeat
	return 0
end seqIndex

/**

Delete the specified index from the sequence

Parameters:
xSeq: The sequence to delete the index from
pIndex: The index to delete

*/
command seqDeleteIndex \
		@xSeq, \
		pIndex

	repeat with i = pIndex to the number of elements in xSeq
		put xSeq[i + 1] into xSeq[i]
	end repeat
	delete variable xSeq[the number of elements in xSeq]
end seqDeleteIndex

/* Insert the value at index pIndex in xSeq, moving values in [pIndex...] up
 * by one. */
command seqInsertIndex \
		@xSeq, \
		pIndex, \
		pValue

	repeat with tIndex = the number of elements in xSeq down to pIndex
		put xSeq[tIndex] into xSeq[tIndex + 1]
	end repeat
	put pValue into xSeq[pIndex]
end seqInsertIndex

function seqSlice \
		pSeq, \
		pFrom, \
		pTo

	if pTo is empty then
		put the number of elements in pSeq into pTo
	else if pTo < 0 then
		add the number of elements in pSeq + 1 to pTo
	else if pTo > the number of elements in pSeq then
		put the number of elements in pSeq into pTo
	end if

	if pFrom < 0 then
		add the number of elements in pSeq + 1 to pFrom
	end if

	if pFrom > pTo or pTo is 0 then
		return empty
	end if

	local tSeq
	repeat with i = pFrom to pTo
		seqPushOntoBack tSeq, pSeq[i]
	end repeat

	return tSeq
end seqSlice

function seqStringList \
		pSeq, \
		pDelimiter, \
		pTrailing

	if pDelimiter is empty then
		put return into pDelimiter
	end if

	local tList
	repeat with x = 1 to the number of elements in pSeq
		if x > 1 then
				put pDelimiter after tList
		end if
		put pSeq[x] after tList
	end repeat

	if pTrailing then
		put pDelimiter after tList
	end if

	return tList
end seqStringList

function seqReversed \
		pSeq

	local tSeq
	repeat with i = the number of elements in pSeq down to 1
		seqPushOntoBack tSeq, pSeq[i]
	end repeat
end seqReversed

/**

Filter a sequence

Parameters:
xSeq: The sequence to filter
pCallback: A command accepting two parameters the element and pContext and
returning true to retain the element
pTarget: The object to dispatch pCallback on
pContext: Additional context for the filter

*/
command seqFilter \
		@xSeq, \
		pCallback, \
		pTarget, \
		pContext

	local tSeq
	repeat with i = 1 to the number of elements in xSeq
		dispatch pCallback to pTarget with xSeq[i], pContext
		if the result then
			seqPushOntoBack tSeq, xSeq[i]
		end if
	end repeat

	put tSeq into xSeq
end seqFilter

command seqSort \
		@xSeq, \
		pKey, \
		pDirection, \
		pType

	if pDirection is empty then
		put "ascending" into pDirection
	end if

	if pType is empty then
		put "text" into pType
	end if

	local tKeys
	put the keys of xSeq into tKeys

	if pKey is empty then
		do format( \
				"sort lines of tKeys %s %s", \
				pDirection, \
				pType)
	else
		do format( \
				"sort lines of tKeys %s %s by xSeq[each][pKey]", \
				pDirection, \
				pType)
	end if

	local tSeq
	repeat for each line tKey in tKeys
		seqPushOntoBack tSeq, xSeq[tKey]
	end repeat

	put tSeq into xSeq
end seqSort

/*******************************************************************************
 *
 *  SET OPERATIONS
 *
 ******************************************************************************/

function setMake
	local tSet
	repeat with i = 1 to the paramCount
		put true into tSet[param(i)]
	end repeat
	return tSet
end setMake

function setMakeV \
		pSeq

	local tSet
	put empty into tSet
	repeat for each element tElement in pSeq
		put true into tSet[tElement]
	end repeat
	return tSet
end setMakeV

function setMakeFromKeys \
		pMap

	local tSet
	put empty into tSet
	repeat for each key tKey in pMap
		put true into tSet[tKey]
	end repeat
	return tSet
end setMakeFromKeys

function setMakeFromElements \
		pMap

	local tSet
	put empty into tSet
	repeat for each element tElement in pMap
		put true into tSet[tElement]
	end repeat
	return tSet
end setMakeFromElements

command setInclude \
		@xSet, \
		pElement

	put true into xSet[pElement]
end setInclude

command setExclude \
		@xSet, \
		pElement

	delete variable xSet[pElement]
end setExclude

command setUnion \
		@xSet, \
		pOtherSet

	union xSet with pOtherSet
end setUnion

command setIntersect \
		@xSet, \
		pOtherSet

	intersect xSet with pOtherSet
end setIntersect

command setDifference \
		@xSet, \
		pOtherSet

	do "difference xSet with pOtherSet"
end setDifference

function setHasMember \
		pSet, \
		pElement

	return pSet[pElement] is true
end setHasMember

function setListMembers \
		pSet, \
		pDelimiter

	combine pSet with pDelimiter as set
	return pSet
end setListMembers

function setListMembersCrDelimiter \
		pSet

	return setListMembers(pSet, numToChar(13))
end setListMembersCrDelimiter

/*******************************************************************************
*
*  ITEM SET OPERATIONS
*
******************************************************************************/

command itemsetInclude \
		@xItemset, \
		pElement

	set the wholeMatches to true
	if pElement is not among the items of xItemset then
		if xItemset is not empty then
			put comma after xItemset
		end if
		put pElement after xItemset
	end if
end itemsetInclude

command itemsetExclude \
		@xItemset, \
		pElement

	split xItemset by comma as set
	delete variable xItemset[pElement]
	combine xItemset with comma as set
end itemsetExclude

command itemsetUnion \
		@xItemset, \
		pOtherItemset

	repeat for each item tItem in pOtherItemset
		itemsetInclude xItemset, tItem
	end repeat
end itemsetUnion

function itemsetUseMember \
		@xItemset, \
		pElement

	if not itemsetHasMember(xItemset, pElement) then
		return false
	end if
	itemsetExclude xItemset, pElement
	return true
end itemsetUseMember

function itemsetHasMember \
		pItemset, \
		pElement

	set the wholeMatches to true
	return pElement is among the items of pItemset
end itemsetHasMember

/*******************************************************************************
*
*  BIT SET OPERATIONS
*
******************************************************************************/

command bitsetInclude \
		@xBitset, \
		pElement

	put xBitset bitOr pElement into xBitset
end bitsetInclude

command bitsetExclude \
		@xBitset, \
		pElement

	put xBitset bitAnd (bitNot pElement) into xBitset
end bitsetExclude

function bitsetHasMember \
		pBitset, \
		pElement

	return (pBitset bitAnd pElement) is not 0
end bitsetHasMember

/*******************************************************************************
*
*  ARRAY OPERATIONS
*
******************************************************************************/

function arrayHasKeys \
		pArray, \
		pKeys

	if the number of elements in pArray is not \
			the number of elements in pKeys then
		return false
	end if

	repeat for each element tKey in pKeys
		if tKey is not among the keys of pArray then
			return false
		end if
	end repeat

	return true
end arrayHasKeys

function arrayFormat \
		pArray, \
		pPrefix

	local tString
	if isSeq(pArray) then
		local tIndex
		put 1 into tIndex
		repeat for each element tElement in pArray
			put pPrefix & "[" & tIndex & "]" & space after tString
			if tElement is an array then
				if isSeq(tElement) and _arrayIsSimpleList(tElement) then
					put _arrayFormatSimpleList(tElement) after tString
				else
					put return & arrayFormat(tElement, pPrefix & "  ") \
						after tString
				end if
			else
				put _arrayFormatAtomic(tElement) after tString
			end if
			put return after tString
			add 1 to tIndex
		end repeat
	else
		local tOrderedKeys
		set the caseSensitive to true
		put the keys of pArray into tOrderedKeys
		sort lines of tOrderedKeys ascending text
		if empty is among the keys of pArray and \
				empty is not among the lines of tOrderedKeys then
			put empty & return before tOrderedKeys
		end if
		repeat for each line tKey in tOrderedKeys
			put pPrefix & tKey & ":" & space after tString
			if pArray[tKey] is an array then
				if isSeq(pArray[tKey]) then
					if _arrayIsSimpleList(pArray[tKey]) then
						put _arrayFormatSimpleList(pArray[tKey]) & return \
							after tString
						next repeat
					end if
				end if
				put return & arrayFormat(pArray[tKey], pPrefix & "  ") \
					after tString
			else
				put _arrayFormatAtomic(pArray[tKey]) after tString
			end if
			put return after tString
		end repeat
	end if
	delete the last char of tString
	return tString
end arrayFormat

function arrayFormatFullKey \
		pArray, \
		pPrefix

	if pPrefix is not empty then
		put "." after pPrefix
	end if
	local tString, tPrefix
	if isSeq(pArray) then
		local tIndex
		put 1 into tIndex
		repeat for each element tElement in pArray
			put pPrefix & tIndex into tPrefix
			if tElement is an array then
				put arrayFormatFullKey(tElement, tPrefix) after tString
			else
				put tPrefix & "=" & _arrayFormatAtomic(tElement) after tString
			end if
			put return after tString
			add 1 to tIndex
		end repeat
	else
		local tOrderedKeys
		set the caseSensitive to true
		put the keys of pArray into tOrderedKeys
		sort lines of tOrderedKeys ascending text
		if empty is among the keys of pArray and \
				empty is not among the lines of tOrderedKeys then
			put empty & return before tOrderedKeys
		end if
		repeat for each line tKey in tOrderedKeys
			put pPrefix & tKey into tPrefix
			if pArray[tKey] is an array then
				put arrayFormatFullKey(pArray[tKey], tPrefix) after tString
			else
				put tPrefix & "=" & _arrayFormatAtomic(pArray[tKey]) \
					after tString
			end if
			put return after tString
		end repeat
	end if
	delete the last char of tString
	return tString
end arrayFormatFullKey

private function _arrayFormatAtomic \
		pValue

	switch _strict_type_of(pValue)
	case "boolean"
		return pValue
	case "number"
		if trunc(pValue) is pValue then
			if pValue < 0 and pValue >= -2^31 then
				return format("%d", pValue)
			else if pValue > 0 and pValue < 2^32 then
				return format("%u", pValue)
			end if
		end if
		return format("%g", pValue)
	case "string"
		return stringEscape(pValue)
	case "data"
		return hexEncode(pValue)
	end switch
end _arrayFormatAtomic

private function _arrayFormatSimpleList \
		pArray

	local tList
	repeat for each element tElement in pArray
		if tElement is a number then
			put _arrayFormatAtomic(tElement) & comma after tList
		else
			put quote & _arrayFormatAtomic(tElement) & quote & comma \
				after tList
		end if
	end repeat
	delete the last char of tList
	return tList
end _arrayFormatSimpleList

private function _arrayIsSimpleList \
		pArray

	repeat for each element tElement in pArray
		switch _strict_type_of(tElement)
		case "name"
		case "string"
			if tElement contains return or \
					tElement contains tab or \
					tElement contains quote then
				return false
			end if
			break
		case "array"
			return false
		default
			break
		end switch
	end repeat
	return true
end _arrayIsSimpleList

private function _strict_type_of \
		pValue

	if pValue is strictly nothing then
		return "nothing"
	else if pValue is strictly a boolean then
		return "boolean"
	else if pValue is strictly an integer or \
			pValue is strictly a real then
		return "number"
	else if pValue is strictly a string then
		return "string"
	else if pValue is strictly a binary string then
		return "data"
	else if pValue is strictly an array then
		return "array"
	else
		throw "unknown type"
	end if
end _strict_type_of

/*******************************************************************************
 *
 *  STRING OPERATIONS
 *
 ******************************************************************************/

function stringEqualExact \
		pString, \
		pOtherString

	set the caseSensitive to true
	set the formSensitive to true
	/* Prepending "!" before each string stops number-like strings being compared
	 * as numbers. */
	return ("!" & pString) is ("!" & pOtherString)
end stringEqualExact

function stringEqualCaseless \
		pString, \
		pOtherString

	/* Prepending "!" before each string stops number-like strings being compared
	 * as numbers. */
	return ("!" & pString) is ("!" & pOtherString)
end stringEqualCaseless

function stringEscape \
		pString

	replace "\" with "\\" in pString
	replace return with "\n" in pString
	replace numToChar(13) with "\r" in pString
	replace tab with "\t" in pString
	replace quote with "\" & quote in pString
	return pString
end stringEscape

function stringUnescape \
		pString

	local tInEscape, tString
	put false into tInEscape
	repeat for each character tChar in pString
		if not tInEscape then
			if tChar is "\" then
				put true into tInEscape
				next repeat
			else
				put tChar after tString
			end if
		else
			switch tChar
			case "t"
				put tab after tString
				break
			case "r"
				put numToChar(13) after tString
				break
			case "n"
				put return after tString
				break
			case quote
			case "\"
				put tChar after tString
				break
			default
				/* This matches the behavior of format */
				put null after tString
				break
			end switch
			put false into tInEscape
		end if
	end repeat
	return tString
end stringUnescape

function stringTitleCaseToDashCase \
		pString

	local tString
	set the caseSensitive to true
	repeat for each character tChar in pString
		if toUpper(tChar) is tChar then
			if tString is not empty then
				put "-" after tString
			end if
			put toLower(tChar) after tString
		else
			put tChar after tString
		end if
	end repeat
	return tString
end stringTitleCaseToDashCase

function stringDashCaseToTitleCase \
		pString

	local tString, tUpper
	put true into tUpper
	repeat for each character tChar in pString
		if tUpper then
			if tChar is "-" then
				put "_" after tString
			else
				put toUpper(tChar) after tString
				put false into tUpper
			end if
		else if tChar is not "-" then
			put tChar after tString
		else
			put true into tUpper
		end if
	end repeat
	return tString
end stringDashCaseToTitleCase

function stringCamelCaseToDashCase \
		pString

	return stringTitleCaseToDashCase(pString)
end stringCamelCaseToDashCase

function stringWrapWithSeparator \
		pString, \
		pLineLength, \
		pLineSeparator

	// Assume a single line of text in pString
	local tLength
	put the number of chars in pString into tLength

	local tString
	put empty into tString

	local tLines
	put ceil(tLength / pLineLength) into tLines
	repeat with i = 0 to tLines - 1
		local tStart, tEnd
		put i * pLineLength + 1 into tStart
		put tStart + pLineLength - 1 into tEnd
		put (char tStart to tEnd of pString) & pLineSeparator after tString
	end repeat

	return tString
end stringWrapWithSeparator

function stringNormalizeLineEndings \
		pString, \
		pLineEnding

	local tLineEndingChars
	switch pLineEnding
	case "cr"
		put numToChar(13) into tLineEndingChars
		break
	case "lf"
		put lf into tLineEndingChars
		break
	case "crlf"
		put crlf into tLineEndingChars
		break
	default
		throw "unknown line-ending kind (stringNormalizeLineEndings)"
	end switch

	return replaceText(pString, "(\r\n|\r|\n)", tLineEndingChars)
end stringNormalizeLineEndings

function stringEncode \
		pString, \
		pEncoding

	local tType, tTag
	_stringMapEncoding pEncoding, tType, tTag
	switch tType
	case "text"
		return textEncode(pString, tTag)
	case "uni"
		return uniDecode(textEncode(pString, "UTF16"), tTag)
	case "iso"
		return macToIso(textEncode(pString, "macroman"))
	case "mac"
		return isoToMac(textEncode(pString, "ISO-8859-1"))
	default
		break
	end switch
	throw "unknown text encoding (stringEncode)"
end stringEncode

function stringDecode \
		pString, \
		pEncoding

	local tType, tTag
	_stringMapEncoding pEncoding, tType, tTag
	switch tType
	case "text"
		return textDecode(pString, tTag)
	case "uni"
		return textDecode(uniEncode(pString, tTag), "UTF16")
	case "iso"
		return textDecode(isoToMac(pString), "macroman")
	case "mac"
		return textDecode(macToIso(pString), "ISO-8859-1")
	default
		break
	end switch
	throw "unknown text encoding (stringDecode)"
end stringDecode

private command _stringMapEncoding \
		pEncoding, \
		@rType, \
		@rTag

	switch pEncoding
	case "ascii"
		put "text" into rType
		put "ASCII" into rTag
		break
	case "utf-8"
	case "utf8"
		put "text" into rType
		put "UTF8" into rTag
		break
	case "utf-16"
	case "utf16"
		put "text" into rType
		put "UTF16" into rTag
		break
	case "utf-16be"
	case "utf16be"
		put "text" into rType
		put "UTF16BE" into rTag
		break
	case "utf-16le"
	case "utf16le"
		put "text" into rType
		put "UTF16LE" into rTag
		break
	case "utf-32"
	case "utf32"
		put "text" into rType
		put "UTF32" into rTag
		break
	case "utf-32be"
	case "utf32be"
		put "text" into rType
		put "UTF32BE" into rTag
		break
	case "utf-32le"
	case "utf32le"
		put "text" into rType
		put "UTF32LE" into rTag
		break
	case "iso-8859-1"
	case "iso88591"
		switch the platform
		case "iphone"
		case "macOS"
			put "iso" into rType
			put "iso88591" into rTag
			break
		case "android"
		case "linux"
			put "text" into rType
			put "iso88591" into rTag
			break
		default
			put empty into rType
			put empty into rTag
			break
		end switch
		break
	case "windows-1251"
		put "uni" into rType
		put "Russian" into rTag
		break
	case "shift_jis"
		put "uni" into rType
		put "Japanese" into rTag
		break
	case "windows-1252"
	case "cp1252"
	case "ansi"
		/* CP-1252 is currently only supported on Windows machines but
		 * ISO-8859-1 should suffice for most purposes */
		switch the platform
		case "iphone"
		case "macOS"
			put "iso" into rType
			put "iso88591" into rTag
			break
		case "android"
		case "linux"
			put "text" into rType
			put "iso88591" into rTag
			break
		case "win32"
			put "text" into rType
			put "CP1252" into rTag
			break
		default
			put empty into rType
			put empty into rTag
			break
		end switch
		break
	case "gb18030"
		put "uni" into rType
		put "SimplifiedChinese" into rTag
		break
	case "euc-kr"
		put "uni" into rType
		put "Korean" into rTag
		break
	case "big5"
		put "uni" into rType
		put "Chinese" into rTag
		break
	case "macintosh"
		switch the platform
		case "iphone"
		case "macOS"
			put "text" into rType
			put "macroman" into rTag
			break
		case "android"
		case "linux"
			put "mac" into rType
			put "macroman" into rTag
			break
		default
			put empty into rType
			put empty into rTag
			break
		end switch
		break
	default
		put empty into rType
		put empty into rTag
		break
	end switch
end _stringMapEncoding

function stringUnquote \
		pString

	repeat for each char tChar in quote & "'"
		if char 1 of pString is tChar and char -1 of pString is tChar then
			return char 2 to -2 of pString
		end if
	end repeat

	return pString
end stringUnquote

/*******************************************************************************
 *
 *  NUMBER OPERATIONS
 *
 ******************************************************************************/

function numberClamp \
		pNumber, \
		pMin, \
		pMax

	return min(max(pNumber, pMin), pMax)
end numberClamp

/*******************************************************************************
 *
 *  HEX OPERATIONS
 *
 ******************************************************************************/

function hexEncode \
		pData

	local tHex
	get binaryDecode("H*", pData, tHex)
	return upper(tHex)
end hexEncode

function hexDecode \
		pHex

	return binaryEncode("H*", pHex)
end hexDecode

/*******************************************************************************
 *
 *  FILE OPERATIONS
 *
 ******************************************************************************/

function fileGetModificationTime \
		pFile

	local tDetailed
	put files(pathDirName(pFile), "detailed-utf8") into tDetailed
	filter tDetailed with _detailedUTF8PathName(pathBaseName(pFile)) & ",*"

	return item 5 of line 1 of tDetailed
end fileGetModificationTime

function fileGetSize \
		pFile

	local tDetailed
	put files(pathDirName(pFile), "detailed-utf8") into tDetailed
	filter tDetailed with _detailedUTF8PathName(pathBaseName(pFile)) & ",*"

	return item 2 of line 1 of tDetailed
end fileGetSize

/* Entry names listed detailed-utf8 files and folders are first normalized NFC
 * then UTF-8 encoded and finally url encoded */
private function _detailedUTF8PathName \
		pName

	return urlEncode(textEncode(normalizeText(pName, "NFC"), "utf8"))
end _detailedUTF8PathName

command fileCopy \
		pFrom, \
		pTo

	if there is a file pTo then
		throw format( \
				"unable to copy file %s to %s - destination exists", \
				pFrom, \
				pTo)
	end if

	local tFromBinary
	binaryfileLoad pFrom, tFromBinary

	if there is a folder pTo then
		binaryfileSave pathJoin(pTo, pathBaseName(pFrom)), tFromBinary
	else
		binaryfileSave pTo, tFromBinary
	end if
end fileCopy

command fileDelete \
		pFile

	if not there is a file pFile then
		exit fileDelete
	end if

	if pFile is empty or \
			not pathIsAbs(pFile) then
		throw format("unable to delete file '%s'", pFile)
	end if

	delete file pFile
	if the result is not empty then
		throw format("delete file failed: %s", it)
	end if
end fileDelete

command fileMove \
		pFrom, \
		pTo

	if there is a file pTo then
		throw format( \
				"unable to move file %s to %s - destination exists", \
				pFrom, \
				pTo)
	end if

	get shell(format("mv \"%s\" \"%s\"", pFrom, pTo))
	if the result > 0 then
		throw format("mv failed: %s", it)
	end if
end fileMove

command textfileSaveNoThrow \
		pFile, \
		pContent, \
		pEncoding

	if pEncoding is empty then
		put "UTF-8" into pEncoding
	end if

	local tContent
	put stringEncode(pContent, pEncoding) into tContent
	put tContent into url ("binfile:" & pFile)
	return the result
end textfileSaveNoThrow

command textfileSave \
		pFile, \
		pContent, \
		pEncoding

	textfileSaveNoThrow pFile, pContent, pEncoding
	if the result is not empty then
		throw format("unable to save text file '%s' - %s", pFile, the result)
	end if
end textfileSave

command textfileLoadNoThrow \
		pFile, \
		@rContent, \
		pEncoding

	local tContent
	put url ("binfile:" & pFile) into tContent
	if the result is not empty then
		return the result
	end if

	if pEncoding is empty then
		put "UTF-8" into pEncoding
	end if

	-- delete BOM if it exists
	if pEncoding begins with "UTF" then
		local tBom
		put stringEncode(numToCodepoint(0xfeff), pEncoding) into tBom

		if tContent begins with tBom then
			delete byte 1 to (the number of bytes in tBom) of tContent
		end if
	end if

	put stringDecode(tContent, pEncoding) into tContent

	-- normalise line endings
	replace CRLF with LF in tContent
	replace numToCodepoint(13) with LF in tContent

	put tContent into rContent

	return empty
end textfileLoadNoThrow

command textfileLoad \
		pFile, \
		@rContent, \
		pEncoding

	textfileLoadNoThrow pFile, rContent, pEncoding
	if the result is not empty then
		throw format("unable to load text file '%s' - %s", pFile, the result)
	end if
end textfileLoad

command binaryfileSave \
		pFile, \
		pContent

	binaryfileSaveNoThrow pFile, pContent
	if the result is not empty then
		throw format("unable to save binary file '%s' - %s", pFile, the result)
	end if
end binaryfileSave

command binaryfileSaveNoThrow \
		pFile, \
		pContent

	put pContent into url ("binfile:" & pFile)
	return the result
end binaryfileSaveNoThrow

command binaryfileLoad \
		pFile, \
		@rContent

	binaryfileLoadNoThrow pFile, rContent
	if the result is not empty then
		throw format("unable to load binary file '%s' - %s", pFile, the result)
	end if
end binaryfileLoad

command binaryfileLoadNoThrow \
		pFile, \
		@rContent

	put url ("binfile:" & pFile) into rContent
	return the result
end binaryfileLoadNoThrow

/*******************************************************************************
 *
 *  PATH OPERATIONS
 *
 ******************************************************************************/

function pathNormPath \
		pPath

	replace "//" with "/" in pPath
	if pPath ends with "/" then
		delete the last codepoint of pPath
	end if

	set the itemdelimiter to "/"
	set the wholematches to true

	local tFirstNonrelativeItem
	repeat for each item tComponent in pPath
		add 1 to tFirstNonrelativeItem
		if tComponent is not ".." then
			exit repeat
		end if
	end repeat

	local tRelativeItem
	put itemOffset("..", pPath, tFirstNonrelativeItem) into tRelativeItem
	repeat while tRelativeItem is not 0
		delete item tFirstNonrelativeItem + tRelativeItem - 1 \
			to tFirstNonrelativeItem + tRelativeItem of pPath
		put itemOffset("..", pPath, tFirstNonrelativeItem) into tRelativeItem
	end repeat

	return pPath
end pathNormPath

function pathAbsPath \
		pPath

	if pathIsAbs(pPath) then
		return pathNormPath(pPath)
	end if

	return pathNormPath(pathJoin(the folder, pPath))
end pathAbsPath

function pathCommonPath
	local tSeq
	repeat with i = 1 to the paramCount
		seqPushOntoBack tSeq, param(i)
	end repeat
	return pathCommonPathV(tSeq)
end pathCommonPath

function pathCommonPathV \
		pPaths

	if pPaths is empty then
		throw "cannot compute common path from empty path list"
	end if

	if seqCount(pPaths) is 1 then
		return pPaths[1]
	end if

	local tCommonPathList, tIndex, tCommonComponent, tAbsolute
	put pathIsAbs(pPaths[1]) into tAbsolute

	repeat with i = 1 to seqCount(pPaths)
		if pathIsAbs(pPaths[i]) is not tAbsolute then
			throw "cannot compute common path from empty path list"
		end if
		put pathNormPath(pPaths[i]) into pPaths[i]
		split pPaths[i] by "/"
	end repeat

	local tFirstPath
	repeat forever
		add 1 to tIndex
		put empty into tCommonComponent
		put true into tFirstPath
		repeat for each element tPath in pPaths
			if tIndex > seqCount(tPath) then
				return seqStringList(tCommonPathList, "/")
			end if
			if tFirstPath then
				put tPath[tIndex] into tCommonComponent
				put false into tFirstPath
			else if tPath[tIndex] is not tCommonComponent then
				return seqStringList(tCommonPathList, "/")
			end if
		end repeat
		seqPushOntoBack tCommonPathList, tCommonComponent
	end repeat
end pathCommonPathV

function pathRelPath \
		pPath, \
		pFolder

	local tAbsolutePath
	put pathAbsPath(pPath) into tAbsolutePath

	if pFolder is empty then
		put the folder into pFolder
	else
		put pathAbsPath(pFolder) into pFolder
	end if

	local tCommonPrefix
	put pathCommonPath(tAbsolutePath, pFolder) into tCommonPrefix

	delete char 1 to the number of chars in tCommonPrefix + 1 of tAbsolutePath
	delete char 1 to the number of chars in tCommonPrefix + 1 of pFolder

	local tPathComponents, tRelativeToComponents, tComponents
	put tAbsolutePath into tPathComponents
	split tPathComponents by "/"
	put pFolder into tRelativeToComponents
	split tRelativeToComponents by "/"

	repeat seqCount(tRelativeToComponents)
		seqPushOntoBack tComponents, ".."
	end repeat

	seqAppend tComponents, tPathComponents
	return pathJoinV(tComponents)
end pathRelPath

function pathBaseName \
		pPath

	local tParts
	put pathSplit(pPath) into tParts
	return tParts[2]
end pathBaseName

function pathDirName \
		pPath

	local tParts
	put pathSplit(pPath) into tParts
	return tParts[1]
end pathDirName

function pathIsAbs \
		pPath

	return codeunit 1 of pPath is "/" or matchText(pPath, "^[a-zA-Z]:/")
end pathIsAbs

function pathJoin
	local tSeq
	repeat with i = 1 to the paramCount
		seqPushOntoBack tSeq, param(i)
	end repeat
	return pathJoinV(tSeq)
end pathJoin

function pathJoinV \
		pComponents

	local tPath, tComponent
	repeat with i = 1 to seqCount(pComponents)
		put pComponents[i] into tComponent
		if tComponent is not empty and \
				the last codeunit of tComponent is not slash and \
				i is not seqCount(pComponents) then
			put slash after tComponent
		end if
		if pathIsAbs(tComponent) then
			put tComponent into tPath
		else
			put tComponent after tPath
		end if
	end repeat
	return tPath
end pathJoinV

function pathSplit \
		pPath

	local tHead, tTail
	if pPath is slash then
		put slash into tHead
		put empty into tTail
	else
		set the itemDelimiter to slash
		put item -1 of pPath into tTail
		put item 1 to -2 of pPath into tHead
		repeat while tHead is not slash and the last codeunit of tHead is slash
			delete the last codeunit of tHead
		end repeat
	end if
	return seqMake(tHead, tTail)
end pathSplit

function pathSplitFront \
		pPath

	local tHead, tTail
	if pPath is slash then
		put slash into tHead
		put empty into tTail
	else
		set the itemDelimiter to slash
		if pPath begins with slash then
			put item 1 to 2 of pPath into tHead
			put item 3 to -1 of pPath into tTail
		else
			put item 1 of pPath into tHead
			put item 2 to -1 of pPath into tTail
		end if
	end if
	return seqMake(tHead, tTail)
end pathSplitFront

function pathExtName \
		pPath

	local tBaseName
	put pathBaseName(pPath) into tBaseName
	set the itemdelimiter to "."
	if the number of items in tBaseName > 1 then
		return item -1 of tBaseName
	else
		return empty
	end if
end pathExtName

function pathLeafName \
		pPath

	local tBaseName
	put pathBaseName(pPath) into tBaseName
	set the itemdelimiter to "."
	if the number of items in tBaseName > 1 then
		return item 1 to -2 of tBaseName
	else
		return tBaseName
	end if
end pathLeafName

/*******************************************************************************
 *
 *  URL OPERATIONS
 *
 ******************************************************************************/

/**
 *
 * Parse a URL string to an array of components
 *
 * Parameters:
 * A UTF-8 encoded then url encoded string.
 *
 * Returns:
 * An array with keys:
 *
 * - scheme: https etc
 * - netloc: example.com
 * - path: /foo/bar/baz.file
 * - parameters: Array of key/value pairs
 * - fragment: anything after # in the url
 * - username
 * - password
 * - port
 *
 */

function urlParse \
		pURL

	constant kURLRegex = "^(?:(?:(([^:\/#\?]+:)?(?:(?:\/\/)(?:(?:(?:([^:@\/#\?]+)(?:\:([^:@\/#\?]*))?)@)?(([^:\/#\?\]\[]+|\[[^\/\]@#?]+\])(?:\:([0-9]+))?))?)?)?((?:\/?(?:[^\/\?#]+\/+)*)(?:[^\?#]*)))?(\?[^#]+)?)(#.*)?"

	local tOrigin, tScheme, tUsername, tPassword, tHost, tNetloc, tPort, \
		tPath, tParameters, tFragment

	if not matchText( \
			pURL, \
			kURLRegex, \
			tOrigin, \
			tScheme, \
			tUsername, \
			tPassword, \
			tHost, \
			tNetloc, \
			tPort, \
			tPath, \
			tParameters, \
			tFragment) then
		envError format("could not parse url '%s'", pURL)
	end if

	local tURLA
	put char 1 to -2 of tScheme into tURLA["scheme"]
	put tNetloc into tURLA["netloc"]
	put tPort into tURLA["port"]

	delete char 1 of tParameters
	if tParameters is not empty then
		put tParameters into tURLA["parameters"]
	end if

	put urlDecodeRFC(char 2 to -1 of tFragment) into tURLA["fragment"]
	put urlDecodeRFC(tUsername) into tURLA["username"]
	put urlDecodeRFC(tPassword) into tURLA["password"]
	put urlDecodeRFC(tPath) into tURLA["path"]

	return tURLA
end urlParse

function urlParseParameters \
		pParameters

	local tParameters
	split pParameters by "&" and "="
	repeat for each key tKey in pParameters
		put urlDecodeRFC(pParameters[tKey]) into tParameters[urlDecodeRFC(tKey)]
	end repeat
	return tParameters
end urlParseParameters

/**

Build a URL string from an array of components

Parse a URL string to an array of components

Parameters:
An array with keys:

- scheme: https etc
- netloc: example.com
- path: /foo/bar/baz.file
- parameters: Array of key/value pairs
- fragment: anything after # in the url
- username
- password
- port

Returns:
A UTF-8 encoded url string

*/
function urlUnparse \
		pURLA

	local tURL
	if pURLA["scheme"] is not empty then
		put pURLA["scheme"] & ":" into tURL
	end if

	put "//" after tURL

	if pURLA["netloc"] is not empty then
		if pURLA["username"] is not empty then
			put urlEncodeRFC(pURLA["username"]) after tURL

			if pURLA["password"] is not empty then
				put ":" & urlEncodeRFC(pURLA["password"]) after tURL
			end if

			put "@" after tURL
		end if

		put urlEncodeRFC(pURLA["netloc"]) after tURL

		if pURLA["port"] is not empty then
			put ":" & pURLA["port"] after tURL
		end if
	end if

	put urlEncodeRFC(pURLA["path"], true) after tURL

	if pURLA["parameters"] is not empty then
		put "?" after tURL
		if the number of elements of pURLA["parameters"] > 0 then
			local tAddAmpersand = false
			repeat for each key tKey in pURLA["parameters"]
				if tAddAmpersand then
					put "&" after tURL
				else
					put true into tAddAmpersand
				end if
				put urlEncodeRFC(tKey) & "=" & \
						urlEncodeRFC(pURLA["parameters"][tKey]) \
					after tURL
			end repeat
		else
			put pURLA["parameters"] after tURL
		end if
	end if

	if pURLA["fragment"] is not empty then
		put "#" & urlEncodeRFC(pURLA["fragment"]) after tURL
	end if

	return tURL
end urlUnparse

function urlEncodeRFC \
		pString, \
		pDontEncodeSlash

	if pString is not strictly a binary string then
		put textEncode(pString, "UTF8") into pString
	end if

	put urlEncode(pString) into pString

	replace "+" with "%20" in pString
	if pDontEncodeSlash then
		replace "%2F" with "/" in pString
	end if

	return pString
end urlEncodeRFC

function urlDecodeRFC \
		pString

	put urlDecode(pString) into pString

	return textDecode(pString, "UTF8")
end urlDecodeRFC


/*******************************************************************************
 *
 *  FOLDER OPERATIONS
 *
 ******************************************************************************/

command folderEnsure \
		pFolder

	folderEnsureNoThrow pFolder
	if the result is not empty then
		throw format("unable to create folder '%s' - %s", pFolder, the result)
	end if
end folderEnsure

command folderEnsureNoThrow \
		pFolder

	if there is a folder pFolder then
		return empty
	end if

	set the itemDelimiter to slash
	repeat with i = 2 to the number of items in pFolder
		local tNewFolder
		put item 1 to i of pFolder into tNewFolder
		if there is no folder tNewFolder then
			create folder tNewFolder
			if the result is not empty then
				return the result
			end if
		end if
	end repeat

	return empty
end folderEnsureNoThrow

/**

Create a temporary folder

Returns:
The full path to the folder

*/
function folderMakeTemp
	local tTempFolder
	put pathJoin(specialFolderPath("temporary"), uuid()) into tTempFolder
	folderEnsure tTempFolder

	return tTempFolder
end folderMakeTemp

command folderDelete \
		pFolder

	if pFolder is empty or \
			not pathIsAbs(pFolder) then
		throw format("unable to delete folder '%s'", pFolder)
	end if

	repeat for each line tFolder in folders(pFolder)
		if tFolder is not ".." then
			folderDelete pathJoin(pFolder, tFolder)
		end if
	end repeat

	repeat for each line tFile in files(pFolder)
		delete file pathJoin(pFolder, tFile)
	end repeat
	delete folder pFolder
end folderDelete

command folderRecurse \
		pRootFolder, \
		pRelativeFolder, \
		pCallback, \
		pTarget, \
		@xContext

	local tCurrentFolder
	put pathJoin(pRootFolder, pRelativeFolder) into tCurrentFolder
	repeat for each line tFile in files(tCurrentFolder)
		dispatch pCallback to pTarget \
			with pRootFolder, pathJoin(pRelativeFolder, tFile), xContext
	end repeat
	repeat for each line tFolder in folders(tCurrentFolder)
		if tFolder is ".." then
			next repeat
		end if
		folderRecurse \
			pRootFolder, \
			pathJoin(pRelativeFolder, tFolder), \
			pCallback, \
			pTarget, \
			xContext
	end repeat
end folderRecurse

command folderCopy \
		pFrom, \
		pTo

	if there is not a folder pTo then
		throw format( \
				"unable to copy folder %s to %s - destination folder does not exist", \
				pFrom, \
				pTo)
	end if

	get shell(format("cp -a \"%s\" \"%s\"", pFrom, pTo))
end folderCopy

command folderCopyContents \
		pFrom, \
		pTo

	if there is not a folder pTo then
		throw format( \
				"unable to copy folder %s to %s - destination folder does not exist", \
				pFrom, \
				pTo)
	end if

	get shell(format("cp -a \"%s/.\" \"%s\"", pFrom, pTo))
end folderCopyContents

command folderCopyRecursive \
		pFrom, \
		pTo

	get shell(format("cp -a \"%s/\" \"%s\"", pFrom, pTo))
end folderCopyRecursive

on folderListCallback \
		pBaseFolder, \
		pRelativeFile, \
		@xContext

	seqPushOntoBack xContext, pRelativeFile
end folderListCallback

function folderList \
		pFolder

	local tContext
	folderRecurse \
		pFolder, \
		"", \
		"folderListCallback", \
		the long id of me, \
		tContext
	return tContext
end folderList

local sFolderList
command folderPush \
		pFolder

	if there is not a folder pFolder then
		throw format( \
				"unable to set current folder to %s - folder does not exist", \
				pFolder)
	end if

	seqPushOntoBack sFolderList, the folder
	set the folder to pFolder
end folderPush

command folderPop
	if there is not a folder seqLast(sFolderList) then
		throw format( \
				"unable to set current folder to %s - folder does not exist", \
				seqLast(sFolderList))
	end if

	local tFolder
	seqPopFromBackInto sFolderList, tFolder
	set the folder to tFolder
end folderPop

/*******************************************************************************
 *
 *  SHELL OPERATIONS
 *
 ******************************************************************************/

local sShellPATHSeq

command shellExecute \
		pCommand

	local tArray
	repeat with i = 2 to the paramCount
		seqPushOntoBack tArray, param(i)
	end repeat
	shellExecuteWithEnvV "", pCommand, tArray
	return it for value
end shellExecute

command shellExecuteWithEnv \
		pEnvironment, \
		pCommand

	local tArray
	repeat with i = 3 to the paramCount
		seqPushOntoBack tArray, param(i)
	end repeat

	shellExecuteWithEnvV pEnvironment, pCommand, tArray
	return it for value
end shellExecuteWithEnv

command shellExecuteV \
		pCommand, \
		pParamSequence

	shellExecuteWithEnvV "", pCommand, pParamSequence
	return it for value
end shellExecuteV

command shellExecuteWithEnvV \
		pEnvironment, \
		pCommand, \
		pParamSequence

	local tShell
	repeat for each element tParam in pParamSequence
		put _shellEscapeParameter(tParam) & space after tShell
	end repeat

	_shellExecute pEnvironment, pCommand, tShell
	return it for value
end shellExecuteWithEnvV

private function _shellEscapeParameter \
		pParam

	if char 1 of pParam is quote then
		/* Assume already quoted */
		return pParam
	end if

	if char 1 of pParam is in "-<>()|;&'" then
		return pParam
	end if

	return quote & pParam & quote
end _shellEscapeParameter

private function _shellPathEnvDelimiter
	switch the platform
	case "win32"
		return ";"
	default
		return ":"
	end switch
end _shellPathEnvDelimiter

private command _shellExecute \
		pEnvironment, \
		pCommand, \
		pArguments

	// Temporarily add the folder containing the target command to $PATH
	shellPushPATH

	if space is not in pCommand then
		shellPrependToPATH pathDirName(pCommand)
	end if

	// TODO: Android shell commands require adjusting the $PATH env var
	// with the java root.

	local tStdout, tStderr, tTempFolder
	put the tempname into tTempFolder
	folderEnsure tTempFolder

	put pathJoin(tTempFolder, "stdout.txt") into tStdout
	put pathJoin(tTempFolder, "stderr.txt") into tStderr

	put merge(" 2>[[tStderr]] 1>[[tStdout]]") after pArguments

	local tCmd, tResult
	repeat for each key tEnvVar in pEnvironment
		put tEnvVar & "=" & quote & pEnvironment[tEnvVar] & quote & " " \
			after tCmd
	end repeat

	if space is not in pCommand then
		put pathBaseName(pCommand) after tCmd
	else
		put quote & pCommand & quote after tCmd
	end if
	put space & pArguments after tCmd

	_shellExecuteRaw tCmd
	put tCmd into tResult["command"]
	put the result into tResult["result"]

	textfileLoad tStdout, tResult["stdout"]
	textfileLoad tStderr, tResult["stderr"]

	folderDelete tTempFolder

	shellPopPATH

	return tResult for value
end _shellExecute

private command _shellExecuteRaw \
		pShellCmd

	local tOldHideConsoleWindows
	put the hideConsoleWindows into tOldHideConsoleWindows
	set the hideConsoleWindows to true

	local tResult
	get shell(pShellCmd)
	put the result into tResult
	set the hideConsoleWindows to tOldHideConsoleWindows
	return tResult
end _shellExecuteRaw

/**

Push the current $PATH environment variable onto a stored sequence

*/
command shellPushPATH
	seqPushOntoBack sShellPATHSeq, $PATH
end shellPushPATH

/**

Pop the last pushed $PATH environment variable from the stored sequence

*/
command shellPopPATH
	if seqCount(sShellPATHSeq) is 0 then
		throw "No $PATH has been pushed"
	end if
	seqPopFromBackInto sShellPATHSeq, $PATH
end shellPopPATH

/**

Append the path to the $PATH environment variable

Parameters:
pPath: A path to a directory

Description:
On windows the path is translated to a shortFilePath and slash is replaced with
backslash. The appropriate $PATH delimiter for the platform is used.

*/
command shellAppendToPATH \
		pPath

	if the platform is "win32" then
		put shortFilePath(pPath) into pPath
		replace slash with backslash in pPath
	end if
	put _shellPathEnvDelimiter() & pPath after $PATH
end shellAppendToPATH

/**

Prepend the path to the $PATH environment variable

Parameters:
pPath: A path to a directory

Description:
On windows the path is translated to a shortFilePath and slash is replaced with
backslash. The appropriate $PATH delimiter for the platform is used.

*/
command shellPrependToPATH \
		pPath

	if the platform is "win32" then
		put shortFilePath(pPath) into pPath
		replace slash with backslash in pPath
	end if
	put pPath & _shellPathEnvDelimiter() before $PATH
end shellPrependToPATH

/*******************************************************************************
 *
 *  ENCRYPTED ARRAY OPERATIONS
 *
 ******************************************************************************/

command encarraySave \
		pFilename, \
		pArray, \
		pPassword

	local tArrayBin
	put arrayEncode(pArray) into tArrayBin

	encrypt tArrayBin using "aes256" with pPassword

	binaryfileSave pFilename, it
end encarraySave

command encarrayLoad \
		pFilename, \
		@rArray, \
		pPassword

	local tArrayEncBin
	binaryfileLoad pFilename, tArrayEncBin

	decrypt tArrayEncBin using "aes256" with pPassword

	put arrayDecode(it) into rArray
end encarrayLoad

/*******************************************************************************
 *
 *  RECT OPERATIONS
 *
 ******************************************************************************/

function rectWidth \
		pRect

	return item 3 of pRect - item 1 of pRect
end rectWidth

function rectHeight \
		pRect

	return item 4 of pRect - item 2 of pRect
end rectHeight

function rectLoc \
		pRect

	return (item 3 of pRect + item 1 of pRect) / 2, \
			(item 4 of pRect + item 2 of pRect) / 2
end rectLoc

function rectLeft \
		pRect

	return item 1 of pRect
end rectLeft

function rectTop \
		pRect

	return item 2 of pRect
end rectTop

function rectRight \
		pRect

	return item 3 of pRect
end rectRight

function rectBottom \
		pRect

	return item 4 of pRect
end rectBottom

function rectOffset \
		pRect, \
		pDx, \
		pDy

	return item 1 of pRect + pDx, item 2 of pRect + pDy, \
			item 3 of pRect + pDx, item 4 of pRect + pDy
end rectOffset

function rectIntersect \
		pRect1, \
		pRect2, \
		@rIntersectRect

	local tRect
	put max(item 1 of pRect1, item 1 of pRect2) into item 1 of tRect
	put max(item 2 of pRect1, item 2 of pRect2) into item 2 of tRect
	put min(item 3 of pRect1, item 3 of pRect2) into item 3 of tRect
	put min(item 4 of pRect1, item 4 of pRect2) into item 4 of tRect

	if item 3 of tRect < item 1 of tRect or \
			item 4 of tRect < item 2 of tRect then
		return false
	end if

	put tRect into rIntersectRect
	return true
end rectIntersect

function rectExpand \
		pRect, \
		pAmount

	return \
			item 1 of pRect - pAmount, \
			item 2 of pRect - pAmount, \
			item 3 of pRect + pAmount, \
			item 4 of pRect + pAmount
end rectExpand

/*******************************************************************************
 *
 *  BOUNDS OPERATIONS
 *
 *  The 'bounds' type represents a two-dimensional area. It is an array with
 *  four keys - left, top, right and bottom. A point (x, y) is in the area
 *  described by a bounds value if left <= x < right, and top <= y < bottom.
 *
 ******************************************************************************/

/* Make a bounds array from a left, top, right and bottom. */
function boundsMake \
		pLeft, \
		pTop, \
		pRight, \
		pBottom

	local tBounds
	put pLeft into tBounds["left"]
	put pTop into tBounds["top"]
	put pRight into tBounds["right"]
	put pBottom into tBounds["bottom"]
	return tBounds
end boundsMake

/* Make a bounds array from a top-left point, a width and a height. */
function boundsMakeXYWH \
		pX, \
		pY, \
		pWidth, \
		pHeight

	local tBounds
	put pX into tBounds["left"]
	put pY into tBounds["top"]
	put pX + pWidth into tBounds["right"]
	put pY + pHeight into tBounds["bottom"]
	return tBounds
end boundsMakeXYWH

/* Returns the width of the area described by pBounds. */
function boundsWidth \
		pBounds

	return pBounds["right"] - pBounds["left"]
end boundsWidth

/* Returns the height of the area described by pBounds. */
function boundsHeight \
		pBounds

	return pBounds["bottom"] - pBounds["top"]
end boundsHeight

/* Returns pBounds translated by pX and pY. */
function boundsOffset \
		pBounds, \
		pX, \
		pY

	add pX to pBounds["left"]
	add pY to pBounds["top"]
	add pX to pBounds["right"]
	add pY to pBounds["bottom"]
	return pBounds
end boundsOffset

/* Returns pBounds having been adjusted by pPadding, where pPadding is an
 * array with left, top, right and bottom keys. The left and top bounds
 * are incremented by the padding, whereas the right and bottom bounds are
 * decremented. */
function boundsPad \
		pBounds, \
		pPadding

	add pPadding["left"] to pBounds["left"]
	add pPadding["top"] to pBounds["top"]
	subtract pPadding["right"] from pBounds["right"]
	subtract pPadding["bottom"] from pBounds["bottom"]
	return pBounds
end boundsPad

/*******************************************************************************
 *
 *  PLATFORM OPERATIONS
 *
 ******************************************************************************/

/* If the current platform is macOS, then return the system version in the
 * string comparable form - XXYYZZ. e.g. 101403. If the platform is not macOS
 * then return empty. */
function macGetSystemVersion
	if the the platform is "macos" then
		set the itemDel to "."
		return format( \
				"%02d%02d%02d", \
				item 1 of the systemVersion, \
				item 2 of the systemVersion, \
				item 3 of the systemVersion)
	else
		return empty
	end if
end macGetSystemVersion

/* If the current platform is android, then return the system version in the
 * string comparable form - XXYYZZ. e.g. 101403. If the platform is not android
 * then return empty. */
function androidGetSystemVersion
	if the the platform is "android" then
		set the itemDel to "."
		return format( \
				"%02d%02d%02d", \
				item 1 of the systemVersion, \
				item 2 of the systemVersion, \
				item 3 of the systemVersion)
	else
		return empty
	end if
end androidGetSystemVersion

/*******************************************************************************
 *
 *  IMAGE OPERATIONS
 *
 ******************************************************************************/

function imageGetDimensions \
		pImageFile

	local tDims
	set the filename of the templateImage to pImageFile
	put (the formattedWidth of the templateImage, \
			the formattedHeight of the templateImage) \
		into tDims
	reset the templateImage
	return tDims
end imageGetDimensions

/*******************************************************************************
 *
 *  DATE & TIME OPERATIONS
 *
 ******************************************************************************/

function datetimeSQLDatetimeToSeconds \
		pSQLDatetime

	return datetimeSQLDateToSeconds(word 1 of pSQLDatetime) + \
			datetimeSQLTimeToSeconds(word 2 of pSQLDatetime)
end datetimeSQLDatetimeToSeconds

function datetimeSQLDateToSeconds \
		pSQLDate

	local tYear, tMonth, tDay
	if not matchText( \
			pSQLDate, \
			"^([0-9]{4})-([0-9]{2})-([0-9]{2})$", \
			tYear, \
			tMonth, \
			tDay) then
		throw "invalid date"
	end if

	local tDate
	put format( \
			"%d,%d,%d,0,0,0,0", \
			tYear, \
			tMonth, \
			tDay) \
		into tDate
	convert tDate to seconds
	if tDate is not an integer then
		throw "invalid date"
	end if

	return tDate
end datetimeSQLDateToSeconds

function datetimeSQLTimeToSeconds \
		pSQLTime

	local tHour, tMin, tSec
	if not matchText( \
			pSQLTime, \
			"^(-?[0-9]{2,3}):([0-9]{2}):([0-9]{2})$", \
			tHour, \
			tMin, \
			tSec) then
		throw "invalid time"
	end if

	return tHour * 3600 + tMin * 60 + tSec
end datetimeSQLTimeToSeconds

function datetimeSQLDatetimeFromSeconds \
		pSeconds

	return format( \
			"%s %s", \
			datetimeSQLDateFromSeconds(pSeconds), \
			datetimeSQLTimeFromSeconds(pSeconds mod 86400))
end datetimeSQLDatetimeFromSeconds

function datetimeSQLDateFromSeconds \
		pSeconds

	convert pSeconds to dateItems
	return format( \
			"%04d-%02d-%02d", \
			item 1 of pSeconds, \
			item 2 of pSeconds, \
			item 3 of pSeconds)
end datetimeSQLDateFromSeconds

function datetimeSQLTimeFromSeconds \
		pSeconds

	local tFormat
	put "%02d:%02d:%02" into tFormat
	if pSeconds mod 1 is not 0 then
		put ".6f" after tFormat
	else
		put "d" after tFormat
	end if

	return format( \
			tFormat, \
			pSeconds div 3600, \
			abs(pSeconds) mod 3600 div 60, \
			abs(pSeconds) mod 60)
end datetimeSQLTimeFromSeconds
