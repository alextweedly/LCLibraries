script "sdbLib"
local sADataStore  -- this is the local (in-memory) store of the data
local sAMetaData  -- the local copy of the meta data
local sATables -- array keyed by table, contains CR delimited list of uuids in this table
local sDefaultTable
local sServerHighestVersion -- highest version held on the server
local sMyHighestVersion -- highest version held locally *as confirmed by server
--                         i.e. local changes do not affect it

local sLastError
local sWaitingForUpload, sFailedUpload, sBuildingUpload

local sResponseTimes

--   Holds the event ID for when / if we need to cancel an outstanding one.
local sEventID

-- config variables
-- set in sdb_init call
local sURL, sAppName, sFilePathName, sUsername, sToken
local sCallback_Destination
local sVT     -- used as line delimiter, because base64encoded may have CRs

-- set in (optional) sdb_Config call
local sRetrySeconds  -- if we cannot get version, try again in this many seconds (and then download?)
local sSafety -- max number of tries for download loop  -- TODO ??
local sDBLimit -- number to transfer in each download (defaults to 5 on server)
constant KMaxInOneGet = 5

global GSTOP

command sdb_Config pRetrySeconds, pSafety, pDBLimit
   if pRetrySeconds is not empty then
      put pRetrySeconds into sRetrySeconds 
   end if
   put pSafety into sSafety
   put pDBLimit into sDBLimit
end sdb_Config

function sdb_GetResponseTimes pClear
   local tASums, tType, tReturn
   repeat for each element E in sResponseTimes
      if the number of words in E <> 3 then
         add 1 to tASums["incomplete"]["count"]
         add 1 to tASums["incomplete"]["total"]
      else
         put word 1 of E into tTYpe
         add 1 to tASums[tType]["count"]
         add word 3 of E - word 2 of E to tASums[tType]["total"]
      end if
   end repeat
   repeat for each key K in tASums
      put K && tASums[K]["count"] && tASums[K]["total"] / tASums[K]["count"] &CR after tReturn
   end repeat
   if pClear then put empty into sResponseTimes
   return tReturn
end sdb_GetResponseTimes


on sdb_Init pURL, pAppName, pFilePathName, pUsername, pToken, pCallback_Destination
   -- pURL - the url of the sync server (e.g. tweedly.net/syncdbserver.lc)
   --         "https://" will be added to the front !!
   -- if pURL is empty, then no cloud capabilities are involved
   --
   -- pFilePathName - path to the folder & file to hold the local database
   -- pUsername - user name (often email address, but need not be)
   -- pToken - auth token, given to the user outside this scope
   -- pCallback_Destination - object to receive callbacks (defaut=current stack)
   
   put numtobyte(11) into sVT
   put pCallback_Destination into sCallback_Destination
   if sCallback_Destination is empty then 
      put the long id of the current stack into sCallback_Destination
   end if
   
   put pAppName into sAppName
   
   _sdb_update_status "yellow"
   
   local tt, tA, tTable
   put empty into sLastError
   put empty into sADataStore
   put empty into sATables
   put "DefaultTable" into sDefaultTable
   put empty into sWaitingForUpload
   put empty into sFailedUpload
   put empty into sBuildingUpload
   
   put 100 into sRetrySeconds
   
   put pURL into sURL
   put pFilePathName into sFilePathName
   put pUsername into sUsername
   put pToken into sToken
   
   logInit sFilePathName
   
   ## If the file does not exist it will be automatically created
   local tTableSQL, tDatabaseFileName
   
   if pFilePathName ends with ".sdb" OR pFilePathName is empty then 
      -- we're fine
   else
      put ".sdb" after sFilePathName
   end if
   
   put empty into sADataStore
   put empty into sAMetaData
   put empty into sATables
   if there is a file sFilePathName then
      local temp, tWholeFile, tUUID, t1
      put the millisecs into t1
      put URL ("binfile:" & sFilePathName) into tWholeFile
   else
      put empty into tWholeFile
   end if
   
   installData tWholeFile
   Info "Init" && the number of lines in the keys of sAMetaData && the millisecs-t1
   
   if sURL is not empty then
      -- check for any uploads outstanding in previous session
      _sdb_initialFillUploadQueue 
      
      -- but first download any from server
      sdb_Download
   end if
end sdb_Init

-- install data - either 
--      local file (on start up)
--      downloaded
private command installData pData, pFromServer
   local tUUID, temp, tA
   local tAOutstanding
   set the itemDel to TAB
   set the lineDel to sVT
   
   repeat for each line L in pData
      switch item 1 of L
         case "status"
            put item 3 of L into tUUID
            if item 2 of L = "done" then
               delete variable tAOutstanding[tUUID]
            else
               put tUUID into tAOutstanding[tUUID]
            end if
            break
         case "data"
            put item 2 of L into tUUID
            local tLine, tWhy
            put "unknown" into tWhy
            try
               put base64Decode(item 3 of L) into temp
               put arrayDecode(temp) into tA
               put tA["meta"] into sAMetaData[tUUID]
               if sAMetaData[tUUID]["status"] = "deleted" then
                  put "deleted" into tWhy
               else
                  put "changed" into tWhy
                  put tA["data"] into sADataStore[tUUID]
               end if
            end try
            put lineOffset(tUUID, sWaitingForUpload) into tLine
            if tLine > 0 AND pFromServer then -- this uuid is in conflict
               logInfo 3, "conflict check" && tUUID && tWhy
               dispatch "Callback_sdb_conflict_check" to sCallback_Destination with tUUID, tWhy, L
               delete line tLine of sWaitingForUpload
            end if
            if tA["meta"]["Version"] > sMyHighestVersion then
               put tA["meta"]["Version"] into sMyHighestVersion
            end if
            local tTable
            put tA["data"]["Table"] into tTable
            if tTable is empty then
               logInfo "Record with no table entry" && tUUID
            else
               if tA["meta"]["version"] = "deleted" then
                  filter sATables[tTable] without tUUID
               end if
               put tUUID & the lineDel after sATables[tTable]
            end if
            break
      end switch
   end repeat
   
   -- and check if there are any outstanding to upload
   if pFromServer then exit installData
   
   repeat for each key K in tAOutstanding
      put K & the lineDel after sWaitingForUpload
   end repeat
end installData

private command _sdb_next_event pMillisecs
   --   put "next event" && pMillisecs &CR after msg
   if pMillisecs is empty then
      put 1000 * sRetrySeconds into pMillisecs
   end if
   local tEvents
   -- cancel any existing event
   if sEventID <> 0 then
      put the pendingMessages into tEvents
      --      put sEventID && tEvents &CR &CR after msg
      filter tEvents with (sEventID & ",*")
      if tEvents is NOT empty AND item 2 of line 1 of tEvents < the the long seconds + pMillisecs then
         -- there is an event, and it is before we have been asked for 
         --   - keep that existing one
         logInfo 3, "keeping existing event :" && the long seconds &&  the long seconds + pMillisecs && line 1 of tEvents && "::"
         exit _sdb_next_event
      end if
      cancel sEventID
   end if
   send "sdb_Download" to me in pMillisecs millisecs
   put the result into sEventID
   logInfo 3, "new event : " && sEventID
end _sdb_next_event

command sdb_Download 
   local tURL
   _sdb_next_event -- i.e. default to retry seconds timer
   
   -- non-blocking; don't even bother getting system version - just try a download
   put _sdb_makeStandard_URL() into tURL
   put "&action=download" after tURL
   put "&oldversion=" & sMyHighestVersion after tURL
   
   put "Download" && the millisecs into sResponseTimes[tURL]
   load URL tURL with message "_sdb_response_download"
   -- and the rest is done when that response comes in ...
end sdb_Download

---- install an array of download responses
--private function _sdb_InstallDownload pAResponse
--   local tA, tARecord, tUUID, temp, t64, tResult
--   local tEncoded, tKeys, tNumericKeys

--   put pAResponse["entries"] into pAResponse
--   if pAResponse is empty then
--      -- not sure why this would ever happen !!
--      logInfo 5, "empty entries in download response"
--      return FALSE
--   end if

--   local tLimits
--   put the extents of pAResponse into tLimits

--   if (item 1 of tLimits) = (item 2 of line 1 of tLimits) AND \
--         pAResponse[item 1 of tLimits]["uuid"] = "Highest" then
--      -- nothing remains to be downloaded
--      put sServerHighestVersion into sMyHighestVersion
--      return FALSE  -- i.e. do we need to download again ?  No.
--   end if

--   -- NB these are numeric
--   repeat with K = (item 1 of tLimits) to (item 2 of line 1 of tLimits)
--      put pAResponse[K] into tA
--      put tA["uuid"] into tUUID
--      if tUUID = "Highest" then next repeat
--      local tTable
--      put tARecord["table"] into tTable

--      if tA["Version"] > sMyHighestVersion then
--         put tA["Version"] into sMyHighestVersion
--      end if
--      local tLine, tWhy
--      put lineOffset(tUUID, sWaitingForUpload) into tLine
--      if tLine > 0 then -- this uuid is in conflict
--         local tLine
--         put lineOffset(pUUID, sWaitingForUpload) into tLine
--         if tLine > 0 then -- this uuid is in conflict
--            logInfo 3, "conflict check" && pUUID && pWhy && formatarray(pA)
--            dispatch "Callback_sdb_conflict_check" to sCallback_Destination with pUUID, pWhy, pA
--            put line tLine of sWaitingForUpload &
--            delete line tLine of sWaitingForUpload
--         end if

--         if tA["status"] = "Deleted" OR tA["data"] = "Deleted" OR tA["data"] = "Delete" then
--            _sdb_conflict_check tUUID, "deleted", tA
--            delete variable sADataStore[tUUID]
--            filter sATables[tTable] without tUUID
--            dbWhere "uuid", tUUID
--            put dbDelete("TheData") into tResult
--            put tResult into sLastError
--         else
--            put tA["data"] into tEncoded
--            put base64decode(tEncoded) into t64
--            put arraydecode(t64) into tARecord
--            put tARecord into tA["data"]

--            -- and deal with possible conflict (NB before changing datastore)
--            _sdb_conflict_check tUUID, "changed", tA

--            put tA into sADataStore[tUUID]
--            put tEncoded into tA["data"]

--            put tARecord["table"] into tTable
--            if sATables[tTable] = 0 then put empty into sATables[tTable]
--            if tUUID is not among the lines of sATables[tTable] then 
--               put tUUID &CR after sATables[tTable]
--               put dbInsert("TheData", tA) into tResult
--               put tResult into sLastError
--            else
--               dbWhere "uuid", tUUID
--               put dbUpdate("TheData", tA) into tResult
--               put tResult into sLastError
--            end if
--         end if
--      end repeat
--      return TRUE
--   end _sdb_InstallDownload

--private command _sdb_conflict_check pUUID, pWhy, pA
--   --   This UUID may be a conflict, if it is on the waiting list for upload
--   local tLine
--   put lineOffset(pUUID, sWaitingForUpload) into tLine
--   if tLine > 0 then -- this uuid is in conflict
--      logInfo 3, "conflict check" && pUUID && pWhy && formatarray(pA)
--      dispatch "Callback_sdb_conflict_check" to sCallback_Destination with pUUID, pWhy, pA
--      delete line tLine of sWaitingForUpload
--   end if
--end _sdb_conflict_check 

-- Insert a new record, into table pTable
-- Return either the uuid if successful, or "Error .."
function sdb_Insert pA, pTable
   local temp, tUUID, tEncoded
   -- add the extra & meta items we need
   if pTable is empty then put sDefaultTable into pTable
   
   put uuid("random") into tUUID
   
   put arrayencode(pA) into temp
   put base64Encode(temp) into tEncoded
   
   local tA
   
   put pTable into tA["meta"]["table"]
   put tUUID into tA["meta"]["uuid"]
   put 0 into tA["meta"]["Version"]
   put todayAsSQL(TRUE, TRUE) into tA["meta"]["DateModified"]
   put sUsername into tA["meta"]["LastModifier"]
   
   put pA into tA["data"]
   
   set the itemDel to TAB
   set the lineDel to sVT
   local tToWrite
   put "data" & TAB & tUUID & TAB & base64Encode(arrayEncode(tA)) & the lineDel after tToWrite
   
   if sFilePathName is not empty then
      -- NB if there is no local file storage, then no point in trying to remember
      --    outstanding upload requests
      put "status" & TAB & "pending" & tUUID & the lineDel after tToWrite
      put tToWrite after URL ("binfile:" & sFilePathName)
   end if
   --  put it into local store as well
   put tA["data"] into sADataStore[tUUID]
   put tA["meta"] into sAMetaData[tUUID]
   put tUUID &CR after sATables[pTable]
   
   if sURL is not empty then
      _sdb_Transaction "Insert", tUUID
   end if
   return tUUID
end sdb_Insert

-- Update a record 
-- NB pA should have all changed fields - others remain unchanged.
-- Return either the uuid if successful, or "Error .."
function sdb_Update pUUID, pA
   local temp, tAOld, tEncoded, tANew
   -- first get a copy of the existing array
   put sADataStore[pUUID] into tAOld
   
   if (pA["Table"] is not empty) AND (pA["Table"] <> tAOld["data"]["Table"]) then
      return "Error: attempt to change the Table to which a record belongs. "
   end if
   
   put tAOld into tANew
   repeat for each key K in pA
      put pA[K] into tANew["data"][K]
   end repeat
   
   -- and encode the new record
   put arrayencode(tANew["data"]) into temp
   put base64Encode(temp) into tEncoded
   
   local tA, tResult
   put pUUID into tA["uuid"]
   put tEncoded into tA["data"] -- the SQLite DB has the encoded record
   
   put tAOld["Version"] into tA["Version"]
   put todayAsSQL(TRUE, TRUE) into tA["DateModified"]
   put sUsername into tA["LastModifier"]
   
   dbWhere "uuid", pUUID
   put dbUpdate("TheData", tA) into tResult
   put tResult into sLastError
   if tResult is empty or tResult is a number then
      -- we successfully added it - put it into local store as well
      put tANew["data"] into tA["data"]
      put tA into sADataStore[pUUID]
      _sdb_Transaction "Update", pUUID, tAOld, tA
      return pUUID
   end if
   -- else, there was some error - return that
   put tResult into sLastError
   return "Error" && sLastError
end sdb_Update

-- Replace a record 

-- NB pA should have the entire record, NOT just a subset such as the changes
-- Return either the uuid if successful, or "Error .."
function sdb_Replace pUUID, pA
   local temp, tAOld, tEncoded
   -- first get a copy of the existing array
   put sADataStore[pUUID] into tAOld
   
   if (pA["Table"] is empty) then
      put tAOld["data"]["Table"] into pA["Table"] 
   else
      if (pA["Table"] <> tAOld["data"]["Table"]) then
         return "Error: attempt to change the Table to which a record belongs. "
      end if
   end if
   
   -- and encode the new record
   put arrayencode(pA) into temp
   put base64Encode(temp) into tEncoded
   
   local tA, tResult
   put pUUID into tA["uuid"]
   put tEncoded into tA["data"] -- the SQLite DB has the encoded record
   
   put tAOld["Version"] into tA["Version"]
   put todayAsSQL(TRUE, TRUE) into tA["DateModified"]
   put sUsername into tA["LastModifier"]
   
   dbWhere "uuid", pUUID
   put dbUpdate("TheData", tA) into tResult
   put tResult into sLastError
   if tResult is empty or tResult is a number then
      -- we successfully added it - put it into local store as well
      put pA into tA["data"]
      put tA into sADataStore[pUUID]
      _sdb_Transaction "Update", pUUID, tAOld, tA
      return pUUID
   end if
   -- else, there was some error - return that
   put tResult into sLastError
   return "Error" && sLastError
end sdb_Replace

-- Delete a record from table pTable
-- Return either the uuid if successful, or "Error .."
function sdb_Delete pUUID
   local temp, tA, tResult, tTable
   
   put sADataStore[pUUID]["data"]["table"] into tTable
   
   dbWhere "uuid", pUUID
   put dbDelete("TheData") into tResult
   put tResult into sLastError
   if tResult is empty or tResult is a number then
      -- store this in Modlog *before* deleting it !
      _sdb_Transaction "Delete", pUUID
      -- We have successfully deleted it
      delete variable sADataStore[pUUID]
      filter sATables[tTable] without pUUID
      return pUUID
   end if
   -- else, there was some error - return that
   put tResult into sLastError
   return "Error" && sLastError
   
end sdb_Delete

function sdb_Query pSoFar, pTable, pKey, pOperator, pValue, pConstruct
   local tL, tR, tYN, temp
   local tYes, tNo
   
   if pConstruct is empty then put "or" into pConstruct
   
   if pOperator is among the items of "contains,~,does not contain,=,<>,begins with," & \
         "ends with,>,<,>=,<=,date>,date>=,date<,date<=,date=,date<>" then
      -- it's an operator we can deal with !!
      if pOperator begins with "date" then
         return "Error: we don't do dates just yet !!" && pOperator
      end if
   else
      return "Error: Unknown operator" && pOperator
   end if
   
   -- NB this defaults to "OR", so it is easy to do a simple query
   local tList
   if pConstruct contains "and" then
      -- 'and' - so narrow down the list so far
      put pSoFar into tList
   else -- 'or' - get new list, and combine
      if pTable = "*" then
         repeat for each key K in sATables
            put sATables[K] after tList
         end repeat
      else
         put sATables[pTable] into tList
      end if
   end if
   
   -- the following incredibly ugly code is simply to avoid doing either of
   --   a. a value() or equivalent for each comparison
   --   b. a multi-entry switch/case for each comparison
   -- WHEN we get "constant time" switches with constant values, 
   --    THEN we can revert from
   --            a single switch with each one being its own loop
   --            to a single loop with big case
   switch pOperator 
      case "="
         repeat for each line L in tList
            if sADataStore[L]["data"][pKey] = pValue then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
      case "<>"
         repeat for each line L in tList
            if sADataStore[L]["data"][pKey] <> pValue then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
      case "<"
         repeat for each line L in tList
            if sADataStore[L]["data"][pKey] < pValue then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
      case "<="
         repeat for each line L in tList
            if sADataStore[L]["data"][pKey] <= pValue then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
      case ">"
         repeat for each line L in tList
            if sADataStore[L]["data"][pKey] > pValue then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
      case ">="
         repeat for each line L in tList
            if sADataStore[L]["data"][pKey] >= pValue then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
      case "~"
      case "contains"
         repeat for each line L in tList
            if sADataStore[L]["data"][pKey] contains pValue then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
      case "does not contain"
         repeat for each line L in tList
            if NOT (sADataStore[L]["data"][pKey] contains pValue) then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
      case "begins with"
         repeat for each line L in tList
            if sADataStore[L]["data"][pKey] begins with pValue then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
         
      default
         local tTest
         repeat for each line L in tList
            put sADataStore[L]["data"][pKey] into tL
            put tL && pOperator && pValue into temp
            put value(temp) into tTest
            if tTest then
               put L &CR after tYes
            else 
               put L & CR after tNo
            end if
         end repeat
         break
   end switch
   
   if pConstruct contains "not" then
      put tNo into tYes
   end if
   if pConstruct contains "or" then
      put _sdb_combine_lines(pSoFar, tYes) into tYes
   end if
   
   return tYes
end sdb_Query

command _sdb_RetryFailure pURL
   _sdb_update_status "red", "retry" && pURL
   -- and put it back at the front of the waiting queue
   put pURL into sFailedUpload
end _sdb_RetryFailure

local sLastStatus, sLastStatusChangeTime
-- update status. Rate limit callbacks to one per second TODO (ten seconds?)
command _sdb_update_status pNew, pWhat
   --   put "status update" && pNew && sLastStatus, sLastStatusChangeTime && the millisecs - sLastStatusChangeTime &CR after msg
   if the millisecs - sLastStatusChangeTime > 1000 OR \ -- one or ten seconds have elapsed: update user
         pNew <> sLastStatus then
      dispatch "CallBack_sdb_Status" to sCallback_Destination with pNew, pWhat
      put pNew into sLastStatus
      put the millisecs into sLastStatusChangeTime
   end if
end _sdb_update_status

--private command _sdb_TransitionState pNew, pWhere, pHandlerName, pSeconds
--   -- transition to new state
--   if pNew = sStateTransition then -- bad transition
--      -- breakpoint
--   end if
--   logInfo "transition" && sStateTransition && pNew && pSeconds && pHandlerName && pWhere
--   if GSTOP is TRUE then
--      logInfo "STopping because of GSTOP"
--      exit _sdb_TransitionState
--   end if
--   put pNew into sStateTransition
--   if pHandlerName is not empty then
--      logInfo "sending" && pHandlerName && pSeconds
--      send pHandlerName to me in pSeconds seconds
--      if pSeconds > 0 then
--         put the result && pWhere && pSeconds into sEventID
--      end if
--   end if
--end _sdb_TransitionState

command _sdb_response_upload pURL, pStatus
   -- called when an upload has received a response
   local tOffset, tURL, tLine, tUUID, tDateModified, tResult
   local tResponse, tAResponse, temp
   local tCountUploaded -- how many in this batch were successfully uploaded
   
   put 0 into tCountUploaded
   logInfo 6, "st start of response_ upload" && sMyHighestVersion && tCountUploaded && sServerHighestVersion
   
   if char 1 of pURL = quote then delete char 1 of pURL
   if char -1 of pURL = quote then delete char -1 of pURL
   
   logInfo "sur status " && tOffset && pStatus && char 1 to 64 of pURL
   
   switch word 1 of pStatus
      case "error"
      case "timeout"
         logInfo 6, "sur " && pStatus && libURLErrorData(pURL)
         logInfo 6, "sur failed with " && pURL
         local t1, t2, t3
         if decompose2(pURL, "[", "]", t1, t2, t3) then
            local tAA
            put jsontoarray("[" & t2 & "]") into tAA
            logInfo 6, "array" && formatarray(tAA)
         end if
         _sdb_RetryFailure pURL, libURLErrorData(pURL)
         unload URL pURL
         break
         
      case "cached"
         --         logInfo "sur good" && URL pURL 
         _sdb_update_status "green"
         put URL pURL into tResponse
         unload URL pURL
         
         try
            put JSONToArray(tResponse) into tAResponse
         catch temp
            put "Error: not JSON : " & tResponse &&":"&& temp into tAResponse["error"]
         end try
         logInfo "upload response " && tResponse
         logInfo "keys" && the keys of tAResponse
         logInfo "upload response array" && formatarray(tAResponse)
         if tAResponse["error"] is not empty then
            logInfo "sur error" && tAResponse["error"]
            break
         end if
         
         if tAResponse["serverhighestversion"] is not empty then
            put tAResponse["serverhighestversion"] into sServerHighestVersion
            delete variable tAResponse["serverhighestversion"]
         end if
         delete variable tAResponse["error"] -- which should leave only numbered entries
         
         -- OR tAResponse[1]["error"] is not empty 
         
         logInfo "extents" && the keys of tAResponse & "::::" & the extents of tAResponse 
         
         -- NB async uploads can now have a multiple entries
         repeat with K = item 1 of the extents of tAResponse to item 2 of the extents of tAResponse
            logInfo "sur " & K & " status" && tAResponse[K]["status"] && tAResponse[K]["error"]
            
            put tAResponse[K]["uuid"] into tUUID
            
            -- this upload is DONE - even if there was a conflict
            local tA
            dbWhere "uuid", tUUID  -- Make ure we get the right one, UUID & MOdifiedDate must match
            dbOrderBy "DateModified"
            put dbGet("ModificationLog") into tA
            dbWhere "uuid", tUUID
            dbWhere "DateModified", tA["DateModified"]
            put empty into tA
            put "Done" into tA["status"]
            put dbUpdate("ModificationLog", tA) into tResult
            logInfo "updated modlog" && K && tUUID && tResult
            
            switch tAResponse[K]["status"] 
               case "Conflict"
                  switch tAResponse[K]["statusdetail"]
                     case "changed"
                        dispatch "Callback_sdb_conflict_resolve"  to sCallback_Destination with tUUID, tAResponse[K]
                        break
                     case "deleted"
                        dispatch "Callback_sdb_conflict_resolve" to sCallback_Destination with tUUID, "deleted"
                        break
                     default
                        logInfo "Conflict with strange detail" && tAResponse[K]["statusdetail"]
                  end switch
                  break
               case "Updated"
               case "Inserted"
               case "Deleted"
                  -- updated OK. we will set the new version number at the end !
                  add 1 to tCountUploaded
                  
                  put tAResponse[K]["Version"] into sADataStore[tUUID]["Version"]
                  
                  local tAVersion
                  put tAResponse[K]["Version"] into tAVersion["Version"]
                  dbWhere "uuid", tUUID
                  put dbUpdate("TheData", tAVersion) into temp
                  break
                  
               default
                  logInfo "Bad result in upload" && formatarray(tAResponse[K]) 
                  break
            end switch
         end repeat
         break
      default
         logInfo "sur default" 
   end switch
   
   -- if not equal, then another upload happened intermingled with ours,
   --     so we will need to download 
   --     (including redundantly getting back those we just uploaded)
   logInfo 6, "after upload" && sMyHighestVersion && tCountUploaded && sServerHighestVersion
   if sMyHighestVersion + tCountUploaded = sServerHighestVersion then
      put sServerHighestVersion into sMyHighestVersion
   end if
   
   put " " & the millisecs after sResponseTimes[pURL]
   
   sdb_Download
   
end _sdb_response_upload

---- UPloading is generally triggered by local changes - so no need for periodic checks
--command sdb_CheckUploadQueue
--   local tA, tKeys
--   --   logInfo "In sdb_CheckUploadQueue" && the number of lines in sWaitingForUpload && line 1 of sWaitingForUpload
--   dispatch "Callback_sdb_uploads_needed" to sCallback_Destination with (the number of lines in sWaitingForUpload)

--   if sWaitingForUpload is empty then
--      _sdb_TransitionState "B", "in checkupload", "sdb_Download", sRetrySeconds
--   else
--      _sdb_TransitionState "F", "in checkupload" && line 1 of sWaitingForUpload
--      _sdb_uploading
--   end if
--end sdb_CheckUploadQueue

---- Here we check for any waiting (e.g. at start-up)
--private command _sdb_initialFillUploadQueue
--   local tA, tKeys

--   --   logInfo "In _sdb_initialFillUploadQueue" 
--   dbWhere "status", "Pending"
--   put dbGet("ModificationLog") into tA
--   put the keys of tA into tKeys
--   if tKeys is not empty then 
--      sort numeric lines of tKeys by tA[each]["DateModified"]
--      repeat for each line L in tKeys
--         --         logInfo "queue for upload" && L && tA[L]["uuid"] && tA[L]["DateModified"] 
--         put tA[L]["uuid"] && tA[L]["DateModified"] &CR after sWaitingForUpload
--      end repeat
--   end if
--end _sdb_initialFillUploadQueue

-- NB we *ONLY* ever do one outstanding upload
-- out of order packets mean we would have the risk of out of order uploads
private command _sdb_uploading
   dispatch "Callback_sdb_uploads_needed" to sCallback_Destination with (the number of lines in sWaitingForUpload)
   -- if we are in the middle of building an upload request, then wait for it
   if sBuildingUpload then 
      exit _sdb_uploading
   end if
   -- if there is one which was tried  but failed then retry it 
   --   logInfo "startingupload" &CR & sWaitingforupload &CR & "-----------"
   if sFailedUpload is not empty then
      put "Upload" && the millisecs into sResponseTimes[sFailedUpload]
      load URL line 1 of sFailedUpload with message "_sdb_response_upload"
      delete line 1 of sFailedUpload
   else
      -- take some off the waiting list, put them into one GET request
      local tUUID, tDateModified
      repeat with II = 1 to KMaxInOneGet
         if sWaitingForUpload is empty then exit repeat
         put word 1 of line 1 of sWaitingForUpload into tUUID
         put word 2 to 3 of line 1 of sWaitingForUpload into tDateModified
         
         delete line 1 of sWaitingForUpload
         
         dbWhere "uuid", tUUID
         dbWhere "DateModified", tDateModified
         local tA, tAThisMod, temp
         put dbGet("ModificationLog") into tA
         put tA[1] into tAThisMod[II]
         
         -- we simply retrieve the whole actual data array and add that to the stored modlog
         put sADataStore[tUUID]["data"] into tA
         put arrayencode(tA) into temp
         put base64Encode(temp) into tAThisMod[II]["data"]
         
         -- and make this into a (single entry) numeric array
         put URLEncode(tAThisMod[II]["DateModified"]) into tAThisMod[II]["DateModified"]
         put tAThisMod[II] into temp  
         put empty into tAThisMod[II]
         put temp into tAThisMod[II]
      end repeat
   end if
   if the number of lines in the keys of tAThisMod > 0 then
      put _sdb_EnqueueForUpload(tAThisMod) into temp
   end if
   
end _sdb_uploading

private function _sdb_makeStandard_URL
   local tURL
   put sURL & "?appname=" & sAppName into tURL
   put "&username=" & sUserName after tURL
   put "&token=" & sToken after tURL
   if sDBLimit is not empty then put "&DBLimit=" & sDBLimit after tURL 
   return tURL
end _sdb_makeStandard_URL

private function _sdb_GetServerVersion pClearServer
   local temp, tIndex,tURL
   
   put _sdb_makeStandard_URL() into tURL
   if pClearServer then
      put "&action=getversionanddelete" after tURL
   else
      put "&action=getversion" after tURL
   end if
   
   put "GetVersion" && the millisecs into sResponseTimes[tURL]
   load URL tURL with message "_sdb_response_getserverversion"
   return empty
end _sdb_GetServerVersion

--command _sdb_clearEvents
--   if sEventID <> 0 then
--      -- we need to cancel the already existing pending event 
--      --    we will create a new one hereare waiting to be ready to do a download
--      cancel word 1 of sEventID
--      put 0 into sEventID
--   end if
--end _sdb_clearEvents

command _sdb_response_download pURL, pStatus
   -- called when a 'download' request has received a response
   local tOffset, tURL, tLine, tUUID, tDateModified, tResult
   local tResponse, tAResponse, temp
   
   put " " & the millisecs after sResponseTimes[pURL]
   --   logInfo "download response " && tResponse
   --   logInfo "upload response array" && formatarray(tAResponse)
   
   switch word 1 of pStatus
      case "error"
      case "timeout"
         put "dwn_r error" && libURLErrorData(pURL)  into tAResponse["error"]
         --         logInfo "sdr error" && tAResponse["error"]
         _sdb_update_status "red", pStatus && tAResponse["error"]
         unload URL pURL
         break
         
      case "cached"
         _sdb_update_status "green"
         --         logInfo "dwn_r good" && URL pURL
         put URL pURL into tResponse
         unload URL pURL
         
         if tResponse begins with "Error" then 
            put "Error:  " & tResponse  into tAResponse["error"]
            break
         end if
         installData tResponse
         
         if tAResponse["error"] is not empty then
            logInfo "dwn_r error" && tAResponse["error"]
         else         
            if tAResponse["ServerHighestVersion"] > sServerHighestVersion then
               put tAResponse["ServerHighestVersion"] into sServerHighestVersion 
            end if
            dispatch "Callback_sdb_downloads_needed" to \
                  sCallback_Destination with sMyHighestVersion, sServerHighestVersion
            -- NB sMyHighestVersion will be modified by sdb_install
            put _sdb_installDownload(tAResponse) into temp
            if sMyHighestVersion < sServerHighestVersion then
               logInfo 6, "downloads needed" && sMyHighestVersion && sServerHighestVersion
               _sdb_next_event 0
            end if
            dispatch "Callback_sdb_updateReceived" to sCallback_Destination
            dispatch "Callback_sdb_downloads_needed" to \
                  sCallback_Destination with sMyHighestVersion, sServerHighestVersion
         end if
         
         -- if we are done downloading, then check for uploads waiting
         logInfo "downloaded" && sMyHighestVersion && sServerHighestVersion
         _sdb_uploading
         break
         
      default
         logInfo "dwn_r default" 
         _sdb_update_status "yellow", pStatus
         break
         
   end switch
end _sdb_response_download


command _sdb_response_getserverversion pURL, pStatus
   -- called when a 'getserverversion' request has rceived a response
   local tOffset, tURL, tLine, tUUID, tDateModified, tResult
   local tResponse, tAResponse, temp
   
   switch word 1 of pStatus
      case "error"
      case "timeout"
         logInfo "gsv_r error" && libURLErrorData(pURL) 
         _sdb_update_status "red", pStatus && libURLErrorData(pURL) 
         break
         
      case "cached"
         logInfo "gsv_r good" && URL pURL && sMyHighestVersion
         _sdb_update_status "green"
         put URL pURL into tResponse
         unload URL pURL
         put JSONToArray(tResponse) into tAResponse
         
         if tAResponse["error"] is not empty then
            logInfo "gsv_r error" && tAResponse["error"] 
            break
         end if
         
         -- and this is the new version number
         put tAResponse["ServerHighestVersion"] into sServerHighestVersion
         
         sdb_Download
         break
         
      default
         logInfo "gsv_r default" 
         _sdb_update_status "yellow", pStatus
         break
         
   end switch
   
   unload URL pURL
   put " " & the millisecs after sResponseTimes[pURL]
   _sdb_next_event 
end _sdb_response_getserverversion

private function _sdb_EnqueueForUpload pA
   local tIndex, tURL, tEntries, tPartTotal, tPartCount
   -- remove the fields not needed (or wanted) by the server
   repeat with i = 1 to item 2 of the extents of pA
      delete variable pa[i]["ID"]
      delete variable pA[i]["Status"]
   end repeat
   put ArrayToJSON(pA) into tEntries
   
   constant kMaxSize = 200
   if the number of chars in tEntries <= kMaxSize then
      put _sdb_makeStandard_URL() into tURL
      put "&entries=" & tEntries after tURL
      logInfo "simple uploading:" & CR & tURL & "------------" & CR 
      put "Upload" && the millisecs into sResponseTimes[tURL]
      load URL tURL with message "_sdb_response_upload"
   else
      local tIDGET, t1, t2
      put UUID() into tIDGet
      put TRUE into sBuildingUpload
      put 1 + (the number of chars in tEntries -1 ) div kMaxSize into tPartTotal
      put 1 into t1
      put kMaxSize into t2
      repeat with tPartCount = 1 to tPartTotal
         put _sdb_makeStandard_URL() into tURL
         put "&part=" & tIDGET && tPartCount && tPartTotal && the number of chars in tEntries after tURL
         put "&entries=" & char t1 to t2 of tEntries after tURL
         add kMaxSize to t1 
         put min(kMaxSize+t2, the number of chars in tEntries) into t2
         put tURL &CR after sFailedUpload
      end repeat
      load URL line 1 of sFailedUpload with message "_sdb_response_upload"
      delete line 1 of sFailedUpload
      put FALSE into sBuildingUpload
   end if
   
end _sdb_EnqueueForUpload

private function _sdb_combine_lines p1, p2
   -- merge two sets of lines, eliminating duplicates
   local pA, pShorter, pLonger
   if p1 is empty then return p2
   if p2 is empty then return p1
   if the number of lines in p1 < the number of lines in p2 then
      put p1 into pShorter
      put p2 into pLonger
   else
      put p1 into pLonger
      put p2 into pShorter
   end if
   put pLonger into pA 
   split pA by CR as set
   repeat for each line L in pShorter
      if NOT pA[L] then
         put L & CR after pLonger
      end if
   end repeat
   return pLonger
end _sdb_combine_lines

-- return a JSON string which contains all the data in the local datastore
--   NB these naturally incllude their UUIDs
function sdb_DataForExport
   local tReturn
   put arraytoJSON(sADataStore) into tReturn
   return tReturn
end sdb_DataForExport

-- disaster recovery - delete (silently) all local entriea, then download
-- from the server from scratch
command sdb_RestoreFromDB pClearServer
   -- delete all local SQLite entries
   local tResult
   dbWhere "uuid <>", empty
   put dbDelete("TheData") into tResult
   dbWhere "uuid <>", empty
   put dbDelete("ModificationLog") into tResult
   --return tResult
   
   -- abandon anything waiting
   put empty into sWaitingForUpload
   put empty into sFailedUpload
   
   -- and empty the local store
   put empty into sADataStore
   put empty into sATables
   
   put 0 into sMyHighestVersion
   -- and trigger an immediate check
   put _sdb_GetServerVersion(pClearServer) into tResult
   _sdb_next_event 0
   
end sdb_RestoreFromDB


function sdb_GetOne pRecord
   local tAR
   put sADataStore[pRecord]["data"] into tAR
   return tAR
end sdb_GetOne

-- return the records as a set (i.. key'ed by uuid)
function sdb_GetSet pRecords
   local tAr, tA
   repeat for each line L in pRecords
      put sADataStore[L]["data"] into tA
      put tA into tAr[L]
   end repeat
   return tAr
end sdb_GetSet

-- return the records as a list (i.e. numerically indexed array)
function sdb_GetList pRecords
   local tAr, tA, tC
   repeat for each line L in pRecords
      add 1 to tC
      put sADataStore[L]["data"] into tA
      put tA into tAr[tC]["data"]
      put L into tAr[tC]["uuid"]
   end repeat
   return tAr
end sdb_GetList

function sdb_QueryFullTable pTable
   local tAr, tList
   if pTable = "*" then
      repeat for each key K in sATables
         put sATables[K] after tList
      end repeat
   else
      put sATables[pTable] into tList
   end if
   return tList
end sdb_QueryFullTable

private command _sdb_Transaction pAction, pUUID, pBefore, pAfter
   local temp, tA, tLastID
   
   put pUUID into tA["uuid"]
   put pAction into tA["action"]
   put "Pending" into tA["status"]
   put sADatastore[pUUID]["Version"] into tA["Version"]
   put todayAsSQL(TRUE, TRUE) into tA["DateModified"] 
   
   -- save just the uuid, (and we'll pick up the complete data when ready to upload)
   
   -- uuid is already in tA ready to be stored - nothing to do
   put dbInsert("ModificationLog", tA) into temp
   -- remove the entries only needed here for the ModLog
   delete variable tA["status"]
   
   -- put this one at the end of the waiting list
   --   logInfo "queued for upload transaction" && tA["uuid"] && tA["DateModified"] 
   put tA["uuid"] && tA["DateModified"] &CR after sWaitingForUpload
   --   logInfo "Transaction" && tA["uuid"] && tA["DateModified"] && line 1 of sWaitingForUpload
   
   sdb_Download
   
end _sdb_Transaction


-- ----------------------------------------------------------------------
--  A number of utility functions which, for me at least, normally live in
--  a common library - but are replicated here to keep sdbLib self-contained.
--
-- Surely, some day, Livecode will have a decent Library management mechanism 
--  and we'll be able to get rid of nonsense like this.
-- ----------------------------------------------------------------------
-- things that would normally be in a common library
local sLogLevel, sLogDestination
private command logInit pDest, pLevel
   if pLevel is empty then put 1 into pLevel   -- i.e. default to everythign comes out
   if pDest is empty then put "msg" into pDest
   put pLevel into sLogLevel
   put pDest into sLogDestination
   if sLogDestination <> "msg" then put "file:" & sLogDestination & "_log.txt" into sLogDestination
   logInfo "Newly initialised"
end logInit

private command logInfo pPriority, pMessage
   if paramcount() = 1 then  -- didn't give a priority - just informational
      put pPriority into pMessage
      put 1 into pPriority
   end if
   if pPriority is empty then put 3 into pPriority
   if sLogDestination is empty then put "msg" into sLogDestination
   if pPriority >= sLogLevel then
      if sLogDestination = "msg" then
         put pMessage &CR after msg
      else
         put pMessage &CR after URL sLogDestination
      end if
   end if
   if pPriority > 5 then put pMessage &CR after msg
end logInfo

private function q p
   return quote & p & quote
end q

private function firstOf
   local temp
   repeat with i = 1 to paramcount()
      put param(i) into temp
      if temp is not empty then exit repeat
   end repeat
   return temp
end firstOf

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
private function SQLAsDate pDateTime, pShort
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
private function SQLAsDateItems pDateTime
   local tDate
   
   if pDateTime is empty then return empty
   
   put (char 1 to 4 of pDateTime & "," ) after tDate
   put (char 6 to 7 of pDateTime & "," ) after tDate
   put (char 9 to 10 of pDateTime & "," ) after tDate
   put (char 12 to 13 of pDateTime & "," ) after tDate
   put (char 15 to 16 of pDateTime & "," ) after tDate
   put (char 18 to 19 of pDateTime & ",0" ) after tDate
   return tDate
end SQLAsDateItems


----------------------------------------------------------------------
--| FUNCTION todayAsSQL
--|
--| Summary: get date[time] in SQL format YYYY-MM-DD HH:MM:SS
--| 
--| Format:  todayAsSQL(pTime)
--|
--| Parameters: pTime - TRUE if the time should be appended
--|
--| Return: the current date[time] in SQL format YYYY-MM-DD HH:MM:SS
----------------------------------------------------------------------
private function todayAsSQL pWithTime, pLong
   local tDate, tDateOut
   put the long internet date into tDate
   convert tDate from internet date to dateitems
   put format("%04d-%02d-%02d", item 1 of tDate, item 2 of tDate, item 3 of tDate) into tDateOut
   if pWithTime then
      put format(" %02d:%02d:%02d", item 4 of tDate, item 5 of tDate, item 6 of tDate) after tDateOut
      if pLong then put "." & the long seconds mod 1 after tDateOut
   end if
   return tDateOut
end todayAsSQL

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
function formatArray pArray, pIndent, pIndentString, pBReak
   local tKeys, tError, tResult
   if pBreak is empty then put "<br>" into pBreak
   put empty into tResult
   if pArray is an array then
      put the keys of pArray into tKeys
      sort lines of tKeys
      repeat for each line tKey in tKeys
         if pArray[tKey] is an array then
            put pIndent & tKey & " = {" & pBreak & CR after tResult
            put formatArray(pArray[tKey], (pIndent & pIndentString), pIndentString, pBreak)  & pBreak & CR after tResult
            put pIndent & "}"  & pBreak & CR after tResult
         else
            put pIndent & tKey & " = " & pArray[tKey] & pBreak & CR after tResult
         end if
      end repeat
   end if
   return tResult
end formatArray
