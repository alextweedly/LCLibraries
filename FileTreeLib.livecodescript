script "FileTreeLib.livecode"

-- FileTree Library
constant kLibraryName = "FileTree"
constant kLibraryVersion = 1.0

constant kASCIIFileTypes = "txt,html,livecodescript,md,python,js,css"

function getFileTreeVersion
   return kLibraryName && kLibraryVersion
end getFileTreeVersion

global gDebug

local sInUse
on libraryStack
   if NOT (sInUse = kLibraryVersion) then
      put kLibraryVersion into sInUse
      -- WE ASSUME common library is in use, so no need to check
      --      loadLibrary "commonLib.livecodescript"
   end if
end libraryStack

function getASCIIFileTypes
   return kASCIIFileTypes
end getASCIIFileTypes


function updateFileTree @pA, pAOld
   -- pA is the new (current) file tree array
   -- pOld is a previous instantiation, with some md5 filled in
   local temp, tChanged
   put empty into tChanged
   repeat for each key K in pA
      repeat for each key L in pA[K]
         if L = "treefileinfo" then next repeat
         put pAOld[K][L] into temp
         if (word 1 of pA[K][L] <> word 1 of temp) OR (word 2 of temp is empty) then
            put SPACE & md5hash( URL ("binfile:" & K & "/" & L)) && \
                  md5hash( URL ("file:" & K & "/" & L)) into word 2 to -1 of pA[K][L]
            put K & TAB & L &CR after tChanged
         else
            put SPACE & word 2 to -1 of pAOld[K][L] into word 2 to -1 of pA[K][L]
         end if
      end repeat
   end repeat
   put arrayencode(pA) into temp
   put temp into URL ("binfile:treefileinfo")
   
   return tChanged
end updateFileTree

function getArrayForTreeNested pAflat
   local temp, tA
   repeat for each key K in pAflat
      put K into temp
      replace "/" with "/ " in temp
      split temp by "/"
      union tA[temp] with pAflat[K]
   end repeat
   return tA
end getArrayForTreeNested


-- ??? how TODO this ???
function getArrayForTreeSizes pAflat, pTopDir
   local temp, tA, tAS
   local tNum, tSize, tBlock
   repeat for each key K in pAFlat
      put 0 into tNum
      put 0 into tSize
      put 0 into tBlock
      set the itemDel to ","
      repeat for each key L in pAFlat[K]
         add 1 to tNum
         put item 1 of pAFlat[K][L] into temp
         add temp to tSize
         add (temp div 4096) to tBlock
      end repeat
      set the itemDel to "/"
      local tTopDir
      put max(1, the number of items in pTopDir) into tTopDir
      
      repeat with II = the number of items in K down to tTopDir
         add tNum to item 1 of tAS[item 1 to II of K]
         add tSize to item 2 of tAS[item 1 to II of K]
         add tBlock to item 3 of tAS[item 1 to II of K]
      end repeat
   end repeat
   -- and then process for sizes
   --   repeat for each key K in tAS
   --      put tAS[K] into temp
   --      replace "/" with space in temp
   --      put pAFlat[K] into pAflat[K && temp]
   --      delete variable pAFlat[K]
   --   end repeat
   --   put getArrayForTreeNested(pAflat) into tA
   return tAS
end getArrayForTreeSizes

function getArrayForTreeFoldersAndFiles pAflat
   local temp, tA
   repeat for each key K in pAflat
      put K into temp
      union tA[temp] with pAflat[K]
   end repeat
   return tA
end getArrayForTreeFoldersAndFiles

function getArrayForTreeFiles pAflat, pDisplayTagged
   local temp, tA
   repeat for each key K in pAflat
      repeat for each key L in pAFlat[K]
         if (pDisplayTagged) then
            put pAflat[K][L] into tA[(char 1 to 2 of L) & K & "/" & (char 3 to -1 of L)]
         else
            put pAflat[K][L] into tA[K & "/" &L]
         end if
      end repeat
   end repeat
   return tA
   
end getArrayForTreeFiles

function countFoldersAndFiles pA
   local tFileCount, tFolderCount
   repeat for each key K in pA
      add 1 to tFolderCount
      add (the number of lines in the keys of pA[K]) to tFileCount
   end repeat
   return tFolderCount && tFileCount
   
end countFoldersAndFiles

function getFileTreeFromURL pUrl
   
   local t1, t2
   
   local time1, time2
   put the millisecs into time1
   local tAflat, temp, tempComplete
   --   put "https://" & pUrl & "/lcWebSync.lc?password=mypass&command=getfiles" into pUrl
   if (pUrl begins with "http://" OR pUrl begins with "https://") then
   else
      put "https://" before pUrl
   end if
   put "/lcWebSync.lc?password=mypass&command=getfiles" after pUrl
   put pURL & CR & CR after msg
   put URL (pUrl) into tempComplete -- this will be kept as complete for debugging !!
   put tempcomplete &CR after msg
   put tempComplete into temp
   
   put lineOffset("data starts here", temp) into t1
   delete line 1 to t1 of temp
   put lineoffset("data ends here", temp) into t2
   put line 1 to t2 of temp into temp
   
   local t3
   put base64Decode(temp) into t3
   put arraydecode(t3) into tAflat
   
   return tAFlat
   
end getFileTreeFromURL

function getFileTreeFromFolder pDir
   local tmp, tA
   put getFileTreeFromFolderWithDetails( pDir, tmp) into tA
   return tA
end  getFileTreeFromFolder pDir

function getFileTreeFromFolderWithDetails pDir, @pUpdates
   -- gets (AND re-saves) the file tree from a folder
   local tFolder, tA1
   put the defaultFolder into tFolder
   
   set the defaultFolder to pDir
   
   local time1, time2
   put the millisecs into time1
   local tAflat, temp
   getArrayOfFiles ".", tAflat
   
   put countFoldersAndFiles(tAflat) into temp
   put the millisecs into time2
   put "loaded and counted" && temp & " in " & time2-time1 &CR after msg
   put the defaultFolder into temp
   
   try
      put arraydecode(URL "binfile:treefileinfo") into tA1
   end try
   
   put the millisecs into time1
   put updateFileTree (tAflat, tA1) into pUpdates
   put the millisecs into time2
   put "updated" && the number of lines in pUpdates && "in" & time2-time1 & CR after msg
   
   put arrayencode(tAflat) into URL "binfile:treefileinfo"
   
   set the defaultFolder to tFolder
   return tAFlat
end getFileTreeFromFolderWithDetails

function getFileTreeInfo pFile
   -- simply gets the file tree from a folder where it must be already saveed
   local tA1, temp
   put URL ("binfile:" & pFile) into temp
   try 
      put arraydecode(temp) into tA1
   end try
   
   return tA1
end getFileTreeInfo


command compareTrees pLocal, pRemote, @pAll, @pSame, @pDifferent, @pLocalOnly, @pRemoteOnly, @pVariations
   -- given the trees for local & remote, we build
   --   all, different, same, local only, remote only
   local temp
   
   put empty into pSame
   put empty into pDifferent
   put empty into pLocalOnly
   put empty into pVariations
   put empty into pAll
   
   put pRemote into pRemoteOnly
   
   local tvl, tvr
   repeat for each key K in pLocal
      repeat for each key L in pLocal[K]
         put pRemote[K][L] into tvr 
         put pLocal[K][L] into tvl
         if tvr is empty then
            put tvl into pLocalOnly[K][L]
            next repeat
         end if
         if (word 2 of tvr = word 2 of tvl) OR (word 3 of tvr = word 3 of tvl) then
            put tvl into pSame[K][L]
         else
            put tvl into pDifferent[K][L]
         end if
         delete variable pRemoteOnly[K][L]
      end repeat
   end repeat
   
   repeat for each key K in pRemoteOnly
      if pRemoteOnly[K] is empty then
         delete variable pRemoteOnly[K]
      end if
   end repeat
   
   -- then build 'all'
   repeat for each key K in pLocal
      repeat for each key L in pLocal[K]
         put pLocal[K][L] into tvl
         put tvl into pAll[K]["L " & L]
      end repeat
   end repeat
   repeat for each key K in pRemote
      repeat for each key L in pRemote[K]
         if NOT (pAll[K]["L " & L] is empty) then
            delete variable pAll[K]["L " & L]
            put pRemote[K][L] into tvl
            put tvl into pAll[K]["B " & L]
         else
            put pRemote[K][L] into tvl
            put tvl into pAll[K]["R " & L]
         end if
      end repeat
   end repeat
   
   -- then build 'variants'
   repeat for each key K in pLocalOnly
      repeat for each key L in pLocalOnly[K]
         put pLocalOnly[K][L] into tvl
         put tvl into pVariations[K]["L " & L]
      end repeat
   end repeat
   repeat for each key K in pRemoteOnly
      repeat for each key L in pRemoteOnly[K]
         put pRemoteOnly[K][L] into tvl
         put tvl into pVariations[K]["R " & L]
      end repeat
   end repeat
   repeat for each key K in pDifferent
      repeat for each key L in pDifferent[K]
         put pDifferent[K][L] into tvl
         put tvl into pVariations[K]["D " & L]
      end repeat
   end repeat
   
end compareTrees

