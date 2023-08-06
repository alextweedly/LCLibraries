script "location utilities"
----> all handlers

global gData, gConfig
global gLoggedInUserData

local sAPlaceNames, sCountPlaceNames

on setLatLongFromPostcode @pA
   local tA
   put findPostCode(pA["postcode"]) into tA
   put tA["longitude"] into pA["longitude"]
   put tA["latitude"] into pA["latitude"]
end setLatLongFromPostcode
   
   function convertPostcodeToLatLong pA
   local tmp, tmp1, tA, tInsertA
   if pA["postcode"] is not empty then
      put findPostCode(pA) into tA
   end if
   
   if tA is an array then
      put tA["longitude"] into pA["longitude"]
      put tA["latitude"] into pA["latitude"]
   end if
   --   printarray "save_loc", pA
   return pA
end convertPostcodeToLatLong


function doAddAPostcode pPostcode
   
   local t_local_debug
   
   local tResult, tADetails, tAObject
   
   local tLong, tLat, tA, tmp
   
   DBWhere "postcode", pPostcode
   put DBGetOne("postcodes") into tA
   printarray "retrieved" && pPostCode, tA
   
   if tA is an array then
      put "already known" && formatarray(tA) into tResult
      return tResult
   end if
   
   local tInsertA, tErr
   put URL ("https://postcodes.io/postcodes/" & pPostCode) into tmp
   pl "got .io" && tmp
   try
      put JSONToArray(tmp) into tA
      --      put arrayFromJson(tmp) into tA
   catch tErr
      breakpoint
   end try
   printarray "tA is", tA
   
   repeat for each item K in "postcode,longitude,latitude"
      put tA["result"][K] into tInsertA[K]
   end repeat
   
   put DBInsert("postcodes", tInsertA) into tmp
   if tmp is not a number then
      printarray "insert postcode" && tmp, tInsertA
   end if
   DBWhere "postcode", pPostcode
   put DBGetOne("postcodes") into tA
   
   if tA is an array then
      put "now inserted" && formatarray(tA) into tResult
      return tResult
   end if
end doAddAPostcode

local sCachePostcodes
function findPostCode pPostcode
   local tLong, tLat, tA
   local tmp, tInsertA
   
   put toupper(trim(pPostcode)) into pPostcode
   if NOT (char -4 of pPostcode = SPACE) then
      put SPACE after char -4 of pPostcode
   end if
   
   if char -3 of pPostcode is not a number then return empty
   if chartoNum(char -2 of pPostcode) < chartonum("A") OR \
         chartoNum(char -2 of pPostcode) > chartonum("~") then return empty
   -- TODO further checks
   
   -- see if it is cached
   if sCachePostcodes[pPostcode] is an array then
      return sCachePostcodes[pPostcode]
   end if
   
   DBWhere "postcode", pPostcode
   put DBGetOne("postcodes") into tA
   
   --   printarray "pars", pA
   --   printarray "res", tA
   
   if tA is an array then
      put tA into sCachePostcodes[pPostcode]
      return tA
   end if
   
   put URL ("https://postcodes.io/postcodes/" & pPostcode) into tmp
   try
      put arrayFromJson(tmp) into tA
   end try
   
   -- check for invalid postcode
   if tA["result"]["postcode"] is empty then
      return empty
   end if
   
   repeat for each item K in "postcode,longitude,latitude"
      put tA["result"][K] into tInsertA[K]
   end repeat
   --   printarray "tInsertA is", tInsertA
   
   put DBInsert("postcodes", tInsertA) into tmp
   if tmp is not a number then
      printarray "findpostcode" && tmp, tInsertA
   end if
   
   DBWhere "postcode", pPostcode
   put DBGetOne("postcodes") into tA
   return tA
   
end findPostCode

-- insert proper icon for a venue
function ramp_output_icon pAObject
   local kA
   
   put ["?", "bed", "bed", "bed", "bed", \
         "?", "?", "?", "?", "?", \
         "university", "school", "clinic-medical", "?", "?", \
         "store", "store", "dumbbell", "?", "?"] into kA
   
   --   repeat with i = 1 to 20
   --      put "question" into kA[i]
   --   end repeat
   --   --   put "hotel" into kA[2]
   --   put "bed" into kA[2]
   --   put "bed" into kA[3]
   --   put "bed" into kA[4]
   --   put "bed" into kA[5]
   
   
   --   --   6 | Restaurant
   --   --   7 | Cafe
   --   --   8 | Bar
   --   --   9 | Gallery
   --   --   10 | Museum
   --   --   11 | Library
   
   --   put "university" into kA[11] -- library - nut looks like ...
   --   put "school" into kA[12]
   
   --   put "clinic-medical" into kA[13]
   --   --   14 | Government offices
   --   --   15 | Hairdresser/Beauty
   
   --   put "store" into kA[16]
   --   put "store" into kA[17]
   --   put "dumbbell" into kA[18]
   --   --   19 is missing !!
   --   --   20 | Other Business
   
   return kA[pAObject["type"]]
   
   --   switch 
   --      case pAObject["type"] < 20
   --         return "<i class='fas fa-" & kA[pAObject["type"]] &"'></i>"
   --      default
   --         return "<i class='fas fa-question'></i>"
   --   end switch
end ramp_output_icon

-- for a newly uploaded file (name = pName), create folder if needed,
--    then put file into folder/originals
--         put resized image into each of small, medium, large, thumbnail
--         etc.
function _doImage pName, pShort, pLong, pCategory, pTitle, pCaption
   local tFolder, tCurFolder, tFilename
   
   put firstOf(pShort, pName) into pShort
   put firstOf(pLong, pName) into pLong
   put firstOf(pCategory, pName) into pCategory
   
   --   pl "type=" && $_FILES[pName]["type"]
   -- first check the type
   if trim($_FILES[pName]["type"]) = "image/jpeg" OR \
         trim($_FILES[pName]["type"]) = "image/jpg" OR \
         trim($_FILES[pName]["type"]) = "image/png" then
      put the defaultfolder into tCurFolder
      set the defaultfolder to gConfig["imagebase"]
      put char 1 to 7 of todayAsSQL() into tFolder
      if NOT (there is a folder tFolder) then
         create folder tFolder
         set the defaultfolder to tFolder
         repeat for each item I in "originals,large,medium,small,thumb"
            create folder I
         end repeat
      else
         set the defaultfolder to tFolder
      end if
      -- make up a file name - that can't be guessed
      put md5hash($_FILES[pName]["name"] & the millisecs) into tFilename
      put "." & char 7 to -1 of $_FILES[pName]["type"] after tFilename
      pl "copy file " & $_FILES[pName]["filename"] && "originals/" & tFilename
      put URL ("binfile:" & $_FILES[pName]["filename"]) into URL ("binfile:originals/" & tFilename)
      
      -- and do the resizes
      repeat for each item I in "large,medium,small,thumb"
         --         pl "resizing" && I && item 1 of gConfig["photo sizes"][I] && item 2 of gConfig["photo sizes"][I]
         get resizeImageFile("originals/" & tFilename, I & "/" & tFilename, \
               item 1 of gConfig["photo sizes"][I], item 2 of gConfig["photo sizes"][I])
      end repeat
      
      -- and then add to the image DB
      local tAImage
      -- ID
      put tFolder into tAImage["folder"]
      put tFilename into tAImage["filename"]
      put $_FILES[pName]["name"] into tAImage["original_name"]
      put pShort into tAImage["shortname"]
      put pLong into tAImage["longname"]
      put pCategory into tAImage["category"]
      put pTitle into tAImage["title"]
      put pCaption into tAImage["caption"]
      put empty into tAImage["tags"]
      put empty into tAImage["status"]
      put 0 into tAImage["_status"]
      local tmp, tResult
      put lcms_updateObjectInDB( "images", "plus", tAImage) into tmp
      printarray "inserted" && tmp, tAImage
      put tAImage["ID"] into tResult
   else
      put 0 into tResult
   end if
   set the defaultfolder to tCurFolder
   pl "returning" && tResult
   return tResult
   
end _doImage

function _doManyImages pTable, pUUID, pName
   local tResult, tShort, tLong, tCategory
   --   printarray "manyimages" && pTable && pName, $_FILES
   logdebug "manyimages" && pTable && pName && formatarray($_FILES)
   
   --   pl "aaa" && the defaultfolder
   
   
   local tCurFolder, tFolder, tFilename
   put the defaultfolder into tCurFolder
   --   logdebug "about to strt 1" && the defaultfolder && tCurFolder 
   --   logdebug "111" && folders()
   --   set the defaultfolder to gConfig["imagebase"]
   try
      --      logdebug "121212" && defaultfolder && tCurFolder
      set the defaultfolder to tCurFolder & "/" &"media/photos"
      --      logdebug "222" && the defaultfolder && the folders
   catch tWhy
      put "error with " && tWhy
      exit to top
   end try
   set the defaultfolder to tCurFolder & "/" &"media/photos"
   --   logdebug "2a2a2a" && the defaultfolder && the folders
   --   pl "2a2a2a" && the defaultfolder && the folders   
   
   logdebug "about to strt 3" && the defaultfolder
   --   pl "about to strt 3" && the defaultfolder
   put char 1 to 7 of todayAsSQL() into tFolder
   logdebug "about to strt 4" && the defaultfolder && tFolder
   --   pl "folder=" & tFolder && the defaultfolder && the folders
   logdebug "folder=" & tFolder
   if NOT (there is a folder tFolder) then
      create folder tFolder
      set the defaultfolder to tFolder
      repeat for each item I in "originals,large,medium,small,thumb"
         create folder I
      end repeat
   else
      set the defaultfolder to tFolder
   end if
   logdebug "now in" && the defaultfolder
   
   logdebug "how many images" && item 2 of line 1 of the extents of $_FILES[pName] && the extents of $_FILES[pName]
   repeat with I = 1 to item 2 of line 1 of the extents of $_FILES[pName]
      put pName & "_" & I into tShort
      put pName & "_" & I into tLong
      put pName & "_" & I into tCategory
      
      -- first check the type
      if trim($_FILES[pName][I]["type"]) = "image/jpeg" OR \
            trim($_FILES[pName][I]["type"]) = "image/jpg" OR \
            trim($_FILES[pName][I]["type"]) = "image/png" then
         
         -- make up a file name - that can't be guessed
         put md5hash($_FILES[pName][I]["name"] & the millisecs) into tFilename
         put "." & char 7 to -1 of $_FILES[pName][I]["type"] after tFilename
         logdebug "copy file " & $_FILES[pName][I]["filename"] && "originals/" & tFilename
         put URL ("binfile:" & $_FILES[pName][I]["filename"]) into URL ("binfile:originals/" & tFilename)
         
         -- and do the resizes
         repeat for each item Isize in "large,medium,small,thumb"
            --         pl "resizing" && Isize && item 1 of gConfig["photo sizes"][I] && item 2 of gConfig["photo sizes"][I]
            get resizeImageFile("originals/" & tFilename, Isize & "/" & tFilename, \
                  item 1 of gConfig["photo sizes"][Isize], item 2 of gConfig["photo sizes"][Isize])
         end repeat
         
         -- and then add to the image DB
         local tAImage
         -- ID
         put empty into tAImage
         put tFolder into tAImage["folder"]
         put tFilename into tAImage["filename"]
         put $_FILES[pName]["name"] into tAImage["original_name"]
         put tShort into tAImage["shortname"]
         put tLong into tAImage["longname"]
         put tCategory into tAImage["category"]
         put empty into tAImage["title"]
         put empty into tAImage["caption"]
         put empty into tAImage["tags"]
         put empty into tAImage["status"]
         put 0 into tAImage["_status"]
         
         local tmp
         put lcms_updateObjectInDB( "images", "plus", tAImage) into tmp
         logdebug "inserted image" && tmp && formatarray(tAImage)
         
         DBWhere "filename", tFilename
         put DBGetOne("images") into tAImage
         
         -- and add a usage of it !!
         local tAUsage
         put empty into tAUsage
         put pTable into tAUsage["tablename"]
         put pUUID into tAUsage["tableUUID"]
         put tAImage["ID"] into tAUsage["imageID"]
         put DBInsert("image_usage", tAUsage) into tmp
         logdebug "inserted usage" && tmp && formatarray(tAUsage)
         
      end if
   end repeat
   set the defaultfolder to tCurFolder
   --   pl "returning" && tResult
   return tResult
   
end _doManyImages

command doSQLNear pA, pRadius
   local tCol, tClauses, tVal
   dbWhere "longitude >=", pA["longitude"] - pRadius
   dbWhere "longitude <=", pA["longitude"] + pRadius 
   
   dbWhere "latitude >=", pA["latitude"] - pRadius
   dbWhere "latitude <=", pA["latitude"] + pRadius
end doSQLNear

--function getSQLNear pA, pRadius
--   local tCol, tClauses, tVal
--   put "longitude >=" into tCol
--   put pA["longitude"] - pRadius into tVal
--   put tCol & tVal &";" after tClauses
--   put "longitude <=" into tCol
--   put pA["longitude"] + pRadius into tVal
--   put tCol & tVal &";" after tClauses

--   put "latitude >=" into tCol
--   put pA["latitude"] - pRadius into tVal
--   put tCol & tVal &";" after tClauses
--   put "latitude <=" into tCol
--   put pA["latitude"] + pRadius into tVal
--   put tCol & tVal after tClauses

--   --   pl "returning" && tClauses
--   return tClauses
--end getSQLNear

function ramp_oneImage pImageID, pSize
   --   pl "1image" && pImageID && pSize
   if pImageID = 0 then return empty
   if pSize is empty then put "small" into pSize
   local tAImage, tResult, tImgSrc
   DBWhere "ID", pImageID
   DBWhere "_status", 1
   put DBGetOne("images") into tAImage
   if tAImage is an array then
      logdebug "one image" && formatarray(tAImage)
      put "/" & gConfig["imageBase"] &"/"& tAImage["folder"] &"/"& pSize &"/"& tAImage["filename"] into tImgSrc
      put "       <img src='" & tImgSrc & "' class='img-fluid rounded-start rounded-3 border border-3' alt='...'>" &CR after tResult
   else
      logdebug "no good-status image" && pImageID
   end if
   return tResult
end ramp_oneImage

function ramp_venue_photos pAVenue, pFull
   local tR1, tR2, tR3, tA, tDiv, tDivEnd
   
   put "<div class='d-flex flex-wrap'>" after tR1
   put "<div class='d-flex'>&nbsp;" into tDiv
   put "</div>"  into tDivEnd
   
   
   local tALl
   if pFull then
   end if
   
   local tResult, tAUsages, tAImage
   --   put tR1 into tResult
   
   DBWhere "tableUUID", pAVenue["_uuid"]
   put DBGet("image_usage") into tAUsages
   logdebug "image usages", tAUsages
   
   local tImgSrc
   repeat for each key K in tAUsages
      put ramp_oneImage(tAUsages[K]["imageID"]) after tResult
   end repeat
   --   put tDivEnd after tResult
   return tResult
end ramp_venue_photos


