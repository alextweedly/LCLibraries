script "udpLogger"
local sActivated, sSocket
on udpLogActivate pTF, pName, pSocket
   if pTF then
      set the allowDatagramBroadcasts to true
      if pSocket is empty then 
         put "8123" into pSocket
      end if
      put "255.255.255.255:" & pSocket into sSocket
      --      put "192.168.1.66:" & pSocket into sSocket
      open datagram socket to sSocket
      udpLogInfo "Activate" && pName
   else
      udpLogInfo "Dectivate"
      close socket sSocket
   end if
   put pTF into sActivated
end udpLogActivate

on udpLogInfo pMsg
   local tA, temp
   if sActivated then
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
end udpLogInfo
