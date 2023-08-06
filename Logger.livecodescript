script "Logger"
local sSocket, sURL, sMSG
on logActivate pMode, pName, pSocket
   
   if pMode is among the items of "udp,all" then
      set the allowDatagramBroadcasts to true
      if pSocket is empty OR pMode = "all" then 
         put "8123" into pSocket
      end if
      put "255.255.255.255:" & pSocket into sSocket
      open datagram socket to sSocket
   end if
   
   if pMode is among the items of "file,url,all" then
      if pMode = "all" then
         put "file:logfile.txt" into pSocket
      end if
      put pSocket into sURL
   end if
   
   if pMode is among the items of "msg,all" then
      put TRUE into sMSG
   end if
   
   logInfo "Activate" && pMode
end logActivate

on logDeactivate
   logInfo "Deactivate"
   if sSocket is not empty then
      close socket sSocket
   end if
   put empty into sURL
   put empty into sMSG
end logDeactivate

on logArray pMsg, pA
   local temp
   put pMsg & CR & formatArray(pA) into temp
   logInfo temp
end logArray

on logInfo pMsg
   local tA, temp
   if sSocket is not empty then
      put pMsg into tA["message"]
      switch word 1 of pMsg
         case "Activate"  
         case "Deactivate"  
            put word 1 of pMsg into tA["type"]
            break
         default
            put "info" into tA["type"]
      end switch
      
      put the executionContexts into tA["executionContexts"]
      put the millisecs into tA["time"]
      put ArrayToJSON(tA) into temp
      write temp to socket sSocket
   end if
   if sURL is not empty then
      put the millisecs & ":" & pMsg &CR after URL sURL
   end if
   if sMSG is not empty then
      put the millisecs &":" & pMsg &CR after msg
   end if
end logInfo
