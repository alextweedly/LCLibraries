script "Simple Animation"
-- Simple Animation Library

local sLog
local sPendingMoves, sNewMoves, sActiveMoves, sFrameRate, sLockTime, sBaseTime, sFrameCount

-- constants for item offset numbers in the ActiveMoves
constant KID=9 , Kx1=2, Ky1=3, Kx2=4, Ky2=5, Ktime1=6, KTime2=7, KPath=8, Kease=1

constant kVERSION = 0.1

function sa.Version
   return kVERSION
end sa.Version

command sa.SetFrameRate pRate
   put pRate into sFrameRate
end sa.SetFrameRate

private function _saExpandEasing pSpec
   -- takes in an entire line of specification of a move
   -- returns it with the easing expanded 
   -- simulate the accelerating and braking parameters
   -- pAccel and pBrake are percentages of TIME
   -- i.e. accel from 0 to pAccel, cruise for a while, and brake for last pBrake
   local tEase, tEaseType, tAccelMS, tCruiseMS, tBrakeMS
   put item Kease of pSpec into tEase
   if tEase is empty then return pSpec
   
   if word 1 of tEase is among the words of "acc future proof" then
      put word 1 of tEase into tEaseType
      delete word 1 of tEase
   else
      -- TODO curremtly we ASSUME it has been converted !!
      --   Is there aother possibility ?
      return pSpec
   end if
   
   -- now calculate the equivalent velocity
   local vEquivalent, VCruise, tDist, tMSecs, tMSecsVirtual
   
   put distance(item Kx1 of pSpec, item Ky1 of pSpec, item Kx2 of pSpec, item Ky2 of pSpec) into tDist
   put item kTime2 of pSpec - item kTime1 of pSpec into tMSecs
   
   put tMSecs * word 1 of tEase / 100 into tAccelMS        -- msecs of acceleration
   put tMSecs * (word 2 of tEase) /100 into tBrakeMS -- msecs of braking
   
   put tMSecs - tAccelMS - tBrakeMS into tCruiseMS
   if tCruiseMS < 0 then
      _saLog "error - bad easing percentages" && pSpec
      return pSpec
   end if
   
   put tDist / tMSecs into vEquivalent -- pixels per msec if it were to be linear
   -- NB both accel and braking times only contribute half distance
   -- D = 0.5 * a1 * t1^2  + V * t2 + 0.5 * a2 * t3^2
   -- D = 1/2 * V * t1 +  V * t2 + V * t3
   -- D = V * (t1/2 + t2 + t3/2)
   -- V = D / (t1/2 + t2 + t3/2)
   -- V = a1 * t1 = a2 * t3
   put tDist / (0.5*tAccelMS + tCruiseMS + 0.5*tBrakeMS) into VCruise
   
   -- calculate accelerations (in pixels / ms^2) acceleration 
   local tRateOfAccel, tRateOfBraking
   put VCruise / tAccelMS into tRateOfAccel
   put VCruise / tBrakeMS into tRateOfBraking
   
   -- calculate distances for up/flat/down
   -- D = 1/2 a t^2
   local tDistAccel, tDistBrake
   put 0.5 * tRateOfAccel * tAccelMS ^ 2 into tDistAccel
   put 0.5 * tRateOfBraking * tBrakeMS ^ 2 into tDistBrake
   
   -- finish with 
   --    time rate dist for accel 
   --    time vel dist for cruise
   --    time rate dist for braking
   put  tAccelMS && tRateOfAccel && tDistAccel && \
         tCruiseMS && VCruise && vCruise * tCruiseMS && \
         tBrakeMS && tRateOfBraking && tDistBrake into item Kease of pSpec 
   return pSpec
   
end _saExpandEasing

command sa.LockMoves
   put empty into sPendingMoves
   put empty into sNewMoves
   put empty into sActiveMoves
   put the millisecs into sLockTime
end sa.LockMoves

command sa.MoveTo pControl, pDest, pArrivalTime, pPath, pEasing
   put pEasing, \   -- easing
         empty, empty, \   -- source
         item 1 of pDest, item 2 of pDest, \  -- dest
         empty, pArrivalTime,  \   -- times
         pPath, pControl & CR after sPendingMoves
   if sLockTime is empty then -- not locked - add this one immediately
      sa.UnlockMoves
   end if
end sa.MoveTo

-- NB moves *from* the loc of the control AT 'starttime', not when this is called
command sa.Move pControl, pSource, pDest, pStartTime, pArrivalTime, pPath, pEasing
   if pSource is empty then
      put (empty,empty) into pSource
   end if
   
   --  KID=9 , Kx1=2, Ky1=3, Kx2=4, Ky2=5, Ktime1=6, KTime2=7, KPath=8, Kease=1
   put pEasing, \
         pSource, pDest, \
         pStartTime, pArrivalTime,  \
         pPath, pControl & CR after sPendingMoves
   if sLockTime is empty then -- not locked - add this one immediately
      get saUnlockMoves()
   end if
end sa.Move

-- moves along a set of points taking a certain time
command sa.MovePointList pControl, pList, pStartTime, pArrivalTime, pPath, pEasing
   local tmp, i, totalLength, tPrev, totaltime
   put 0 into i
   put 0 into totalLength
   repeat for each line L in pList
      if tPrev is empty then 
         put L into tPrev
         next repeat
      end if
      add distance(tPrev, L) to totalLength
      put L into tPrev
   end repeat
   
   put empty into tPrev
   local tStart, tNext
   put pArrivalTime - pStartTime into totaltime
   put pStartTime into tStart
   
   repeat for each line L in pList
      if tPrev is empty then 
         put L into tPrev
         next repeat
      end if
      put tSTart + round( distance(tPrev, L) / totalLength * totaltime) into tNext
      _saLog "edge" && tPrev && L && tSTart && tNext 
      sA.Move pControl, tPrev, L, tStart, tNext, pPath, pEasing
      put tNext into tStart
      put L into tPrev
   end repeat
end sa.MovePointList

on sa.UnlockMoves
   --   put sPendingMoves into sNewMoves
   put sPendingMoves into sNewMoves
   
   put empty into sPendingMoves
   put empty into sLockTime
   
   if sFramerate is empty OR sFrameRate = 0  then -- ensure we have a valid frame rate
      put 25 into sFramerate
   end if
   
   put the millisecs into sBaseTime    -- all ms times are based from this !!
   if the pendingMessages contains "saFrameTimer" then
      -- already something going !!
   else
      send "sa.FrameTimer" to me in 0 millisecs
      put 0 into sFrameCount
   end if
end sa.UnlockMoves

on sa.StopMoving
   put empty into sActiveMoves
   put empty into sNewMoves
end sa.StopMoving

-- NB if we are in the IDE then we may brak to debugger, so can't just use
--   the millisecs - so we'll count frames in that case.
on sa.FrameTimer
   local tim1, timetaken
   local tID, tx1, ty1, tx2, ty2, tt1, tt2, tPath, tEase
   local  tloc2, tx, ty, dx, dy, tCtl, tmp, tHeight
   
   lock screen
   if environment() = "development" then
      add 1 to sFrameCount
      put sFrameCount * (1000 div sFramerate) into tim1
   else
      put the millisecs - sBaseTime into tim1
   end if
   
   -- deal with any newly released into active status
   repeat for each line L in sNewMoves
      add tim1 to item Ktime1 of L  
      add tim1 to item Ktime2 of L  
      put L &CR after sActiveMoves
   end repeat
      
   put empty into sNewMoves
   local tContinuing
   repeat for each line L in sActiveMoves
      
      put item Ktime1 of L into tt1
      if tt1 > tim1 then  -- not started moving yet
         put L &CR after tContinuing
         next repeat
      end if
      put item KID of L into tID
      put item Kx1 of L into tx1
      put item Ky1 of L into ty1
      if tx1 is empty then
         -- no location specified - use the current loc
         -- NB MUST do this here and now, not when placed into active state, because
         --    this control may be still moving in another 'move' action
         put the loc of tID into tmp
         put item 1 of tmp into tx1
         put tx1 into item Kx1 of L
         put item 2 of tmp into ty1
         put ty1 into item Ky1 of L
      end if
      
      if word 1 of item Kease of L is not empty then 
         put _saExpandEasing(L) into L
      end if
      
      put item Kx2 of L into tx2
      put item Ky2 of L into ty2
      put item Ktime2 of L into tt2
      put item Kpath of L into tPath
      put item Kease of L into tEase
      
      -- get the current time as a percentage of the time to travel
      local tDone, tRatio, tTotal
      put tim1 - tt1 into tDone
      put tt2 - tt1 into tTotal
      put min(1, tDone / tTotal) into tRatio
      
      -- but for non-linear, get ratio as distance rather than time
      
      if tEase is not empty then
         
         local tAccelMS, tRateOfAccel, tDistAccel
         local tCruiseMS, vCruise, tDistCruise
         local tBrakeMS, tRateOfBrake, tDistBrake
         put word 1 of tEase into tAccelMS
         put word 2 of tEase into tRateOfAccel
         put word 3 of tEase into tDistAccel
         
         put word 4 of tEase into tCruiseMS
         put word 5 of tEase into vCruise
         put word 6 of tEase into tDistCruise
         
         put word 7 of tEase into tBrakeMS
         put word 8 of tEase into tRateOfBrake
         put word 9 of tEase into tDistBrake
         
         -- remember tDone here is time
         local tDistance
         switch
            case tDone <= word 1 of tEase -- in accel phase
               put 0.5 * tRateOfAccel * tDone ^ 2 into tDistance
               break
            case tDone <= word 1 of tEase + word 4 of tEase -- cruising
               put tDone - tAccelMS into tDone -- time cruising
               put tDistAccel + tDone * vCruise into tDistance
               break
            default -- braking or done
               -- essentially, do this backwards !!
               local tmp1
               put tAccelMS + tCruiseMS + tBrakeMS - tDone into tmp1 -- time left for braking
               put 0.5 * tRateOfBrake * tmp1 ^ 2 into tDistance
               put tDistAccel + tCruiseMS * vCruise + tDistBrake - tDistance into tDistance
               break
         end switch
         -- NB we have converted tTotal, tDone to distance instead of time:- now get the ratio
         put tDistance / distance(tx1, ty1, tx2, ty2)  into tRatio
      end if
      
      put tx1 + tRatio * (tx2 - tx1) into tx
      put ty1 + tRatio * (ty2 - ty1) into ty
      
      -- calculate new point on line
      put tx1 + tRatio * (tx2 - tx1) into tx
      put ty1 + tRatio * (ty2 - ty1) into ty
      
      -- and then modify as appropriate for the path kind needed
      switch word 1 of tPath
         case "hop"
            local tMid, tLen2
            put word 2 of tPath into tHeight
            if abs(tx2 - tx1) > abs(ty2 - ty1) then
               -- more horizontal (change Y)
               put abs( (tx2 - tx1) / 2) into tLen2
               put abs( (tx1 + tx2) / 2) into tMid
               put abs(tMid - tx) into tmp -- how far away from mid-pt
               put (tmp ^ 2) / (tLen2 ^ 2) into tmp
               put ty + tHeight * (1 - tmp) into ty
            else
               -- more vertical
               put abs( (ty2 - ty1) / 2) into tLen2
               put abs( (ty1 + ty2) / 2) into tMid
               put abs(tMid - ty) into tmp -- how far away from mid-pt
               put (tmp ^ 2) / (tLen2 ^ 2) into tmp
               _saLog ty1 && ty2 && ty && tmp && tx && tHeight * (1 - tmp)
               put tx + tHeight * (1 - tmp) into tx
            end if
            _saLog "set to " && tx && ty
            break
         case "linear"
         default
            break
      end switch
      set the loc of tID to tX, tY
      
      if tim1 < tt2 then
         put L &CR after tContinuing -- still going
      else
         dispatch "saMoveDone" to tID -- finished - inform user
      end if
   end repeat
   put tContinuing into sActiveMoves
   
   put the millisecs - sBaseTime - tim1 into timetaken
   _saLog "timetaken" && timetaken
   
   if timetaken > (1000 div sFramerate) then
      _saLog "problem" && timetaken && (1000 div sFramerate) * timetaken
   end if
   
   if sActiveMoves is not empty then
      if environment() = "development" then
         _saLog "next in" && (1000 div sFramerate)
      else
         _saLog "next in" && (1000 div sFramerate)-timetaken
      end if
      send "sa.FrameTimer" to me in (1000 div sFramerate)-timetaken millisecs
   end if
   unlock screen
end sa.FrameTimer

-- lifted from Animation Engine
private function distance -- x1,y1, x2,y2
   -- Unglaublich wie viel code man schreibt nur um die Parameter zu checken. Wär chic das schlauer zu regeln...
   
   local adjacentLeg,hypotenuse,i,oppositeLeg
   local theValue,x1,x2,y1
   local y2
   try
      repeat with i=1 to paramcount()
         if i<paramcount() then
            put param(i)&"," after theValue
         else
            put param(i) after theValue
         end if
      end repeat
      
      repeat with i=1 to the number of items of theValue
         if item i of theValue is not a number then
            return "Error: All Parameters must be numbers!"
            exit distance
            exit repeat
         end if
      end repeat
      
      put item 1 of theValue into x1
      put item 2 of theValue into y1
      put item 3 of theValue into x2
      put item 4 of theValue into y2
      if y2 is empty then
         return "Error: Syntax is distance(x1,y1,x2,y2)"&cr&theValue
      end if
      put x1-x2 into oppositeLeg
      put y1-y2 into adjacentLeg
      put round(sqrt (oppositeLeg^2+adjacentLeg^2)) into hypotenuse
      return hypotenuse
   catch theerror
      return "error: "&theError
   end try
end distance

on _saLog p
   -- very rudimentary logging
   put p &CR after sLog
   --   put p &CR after msg
end _saLog
