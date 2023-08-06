script "LRSplitterBehavior"
-- behavior stack for the Left-Right splitter

-- splits to a left and a right part

##############################
-- resizing of splitter pane, adjusting geometry

-- TODO extend uAdjust to allow relative adjustments?!?

local sDragging

local sHiddenLeft, sHiddenRight, sLastLeftWidthFraction
local sIDDivider, sIDLeft, sIDRight

private command _init
   local tIDs, tmp
   --   pl "initing" && the long name of me
   put  the childControlIDs of me into tIDs
   try
      put the long id of control id line 2 of tIDs into sIDLeft
      put the long id of control id line 3 of tIDs into sIDRight
      put the long id of control id line 4 of tIDs into sIDDivider
      
      --      pl the short name of sIDLeft && \
      --      the short name of sIDRight&& \
      --      the short name of sIDDivider 
      if the short name of sIDLeft begins with "L_" AND \
            the short name of sIDRight begins with "R_" AND \
            the short name of sIDDivider = "Divider" then
         exit _init
      end if
   catch tmp
   end try
   
   put "Bad group contents" &CR after msg
   put empty into sIDDivider
   put empty into sIDLeft
   put empty into sIDLeft
   
end _init

on hideLeft
   if sHiddenRight OR sHiddenLeft then
      -- cannot hide both, or it is already hidden
      exit hideLeft
   end if
   
   if sIDDivider is empty then _init
   put TRUE into sHiddenLeft
   put the width of sIDLeft / the width of me into sLastLeftWidthFraction
   set the vis of sIDLeft to FALSE
   
   set the width of sIDRight to the width of me
   set the right of sIDRight to the right of me
   send "resizecontrol" to me
   
end hideLeft

on showLeft pHowMuch
   if sIDDivider is empty then _init
   
   -- always do this, so it can either show it after hiding, or change width
   put FALSE into sHiddenLeft
   local tWL, tWR
   if pHowMuch is a number then
      if pHowMuch <= 1 then
         put pHowMuch into sLastLeftWidthFraction
      else
         put pHowMuch / the width of me into sLastLeftWidthFraction
      end if
   end if
   put the width of me * sLastLeftWidthFraction into tWL
   put the width of me - tWL into tWR
   
   set the width of sIDLeft to tWL
   set the left of sIDLeft to the left of me
   
   set the width of sIDRight to tWR
   set the right of sIDRight to the right of me
   set the vis of sIDLeft to TRUE
   send "resizecontrol" to me
   
end showLeft

on hideRight
   if sHiddenRight OR sHiddenLeft then
      -- cannot hide both, or already hidden
      exit hideRight
   end if
   
   if sIDDivider is empty then _init
   put TRUE into sHiddenRight
   put the width of sIDLeft / the width of me into sLastLeftWidthFraction
   set the vis of sIDRight to FALSE
   
   set the width of sIDLeft to the width of me
   set the right of sIDLeft to the right of me
   send "resizecontrol" to me
   
end hideRight

on showRight pHowMuch
   if sIDDivider is empty then _init
   
   put FALSE into sHiddenRight
   local tWL, tWR
   
   if pHowMuch is a number then
      if pHowMuch <= 1 then
         put 1-pHowMuch into sLastLeftWidthFraction
      else
         put 1 - (pHowMuch / the width of me) into sLastLeftWidthFraction
      end if
   end if
   
   put  the width of me * sLastLeftWidthFraction into tWL
   put the width of me - tWL into tWR
   
   set the width of sIDLeft to tWL
   set the left of sIDLeft to the left of me
   
   set the width of sIDRight to tWR
   set the right of sIDRight to the right of me
   set the vis of sIDRight to TRUE
   send "resizecontrol" to me
   
end showRight

on mouseMove x,y
   if sIDDivider is empty then _init
   if sIDDivider is empty then exit mouseMove
   
   if sDragging then -- now we change sizes of the panes
      if the mouse is not down then
         set the defaultCursor to 0
         exit mouseMove
      end if
      lock screen
      local tNewWidthForLeft, tNewWidthForRight
      
      put x - the left of me into tNewWidthForLeft
      
      -- catch for mouse <> min of left pane
      if tNewWidthForLeft < the uMinLeft of me then 
         put the uMinLeft of me into tNewWidthForLeft
      end if
      
      if the uMinLeft of me + the uMinRight of me > the width of me then
         -- we cannot fit both min sizes, just accept right pane narrower
         put the width of me - tNewWidthForLeft into tNewWidthForRight
      else 
         put the width of me - tNewWidthForLeft into tNewWidthForRight
         if tNewWidthForRight < the uMinRight of me then
            put the uMinRight of me into tNewWidthForRight
            put the width of me - tNewWidthForRight into tNewWidthForLeft
         end if
      end if
      
      set the width of sIDRight to tNewWidthForRight
      set the right of sIDRight to the right of me
      
      set the width of sIDLeft to tNewWidthForLeft
      set the left of sIDLeft to the left of me
      
      setDivider the left of me + tNewWidthForLeft
      
      unlock screen
      -- end changing sizes of the panes
      
   else
      -- not dragging, default testing if over a divider line 
      local tDividerX
      put (the left of sIDDivider + the right of sIDDivider) / 2 into tDividerX
      
      -- if we are over a divider then change cursor   
      
      local tOffset, tSensitivity
      put the uDividerOffset of me into tOffset
      if tOffset is empty then put 4 into tOffset
      put the uDividerSensitivity of me into tSensitivity
      if tSensitivity is empty then put 2 into tSensitivity
      
      if (x > tDividerX - tSensitivity and x < tDividerX + tSensitivity) AND \
            (y > the top of me + tOffset  and y < the bottom of me - tOffset) then
         set the defaultcursor to 31
         lock cursor
      else
         if the defaultcursor <> 0 then
            set the defaultcursor to 0
            unlock cursor
         else
            pass mouseMove
         end if
      end if
   end if
end mouseMove

on resizeControl
   if sIDDivider is empty then _init
   
   local tRme, tRLeft, tRRight, tY1, tY2
   put the rect of me into tRme
   
   set the rect of grc "Backdrop" of me to tRme
   switch
      case sHiddenLeft  
         set the rect of sIDRight to tRme
         setDivider the left of me
         break
      case sHiddenRight
         set the rect of sIDLeft to tRme
         setDivider the right of me
         break
      default
         put the rect of sIDLeft into tRLeft
         put the rect of sIDRight into tRRight
         put item 2 of tRme into tY1
         put item 4 of tRme into tY2
         
         put tY1 into item 2 of tRLeft
         put tY1 into item 2 of tRRight
         put tY2 into item 4 of tRLeft
         put tY2 into item 4 of tRRight
         
         local tDiffLeft, tDiffRight, tRatio, tWL, tWR
         put item 3 of tRLeft - item 1 of tRLeft into tWL
         put item 3 of tRRight - item 1 of tRRight into tWR
         
         -- does this change affect L, or R or borh ?
         switch the uAdjust of me
            case "left only"
               set the rect of sIDRight to\
                     the right of me - tWR, tY1, the right of me, tY2
               set the rect of sIDLeft to\
                     the left of me, tY1, the right of me - tWR, tY2
               setDivider the right of me - tWR
               break
            case "right only"
               set the rect of sIDLeft to\
                     the left of me, tY1, the left of me + tWL, tY2
               set the rect of sIDRight to\
                     the left of me + tWL, tY1, the right of me, tY2
               setDivider the left of me + tWL
               break
            case "both"
            default
               put tWL / (tWL + tWR) into tRatio
               put round(the width of me * tRatio) into tWL
               --               pl "setting" && sIDLeft && sIDRight
               set the rect of sIDLeft to\
                     the left of me, tY1, the left of me + tWL, tY2
               set the rect of sIDRight to\
                     the left of me + tWL, tY1, the right of me, tY2
               setDivider the left of me + tWL
               break
         end switch
   end switch
end resizeControl

on setDivider pX
   local tOffset
   put the uDividerOffset of me into tOffset
   if tOffset is empty then put 4 into tOffset
   
   if sIDDivider is empty then _init
   switch the uDividerStyle of me
      case "double lines"
         local tGap, tLength, tMiddle
         put the uDividerGap of me into tGap
         if tGap is empty then put 4 into tGap
         put tGap div 2 into tGap
         put the uDividerLength of me into tLength
         if tLength is empty then put 40 into tLength
         put (the top of me + the bottom of me) / 2 into tMiddle
         set the points of sIDDivider to \
               pX-tGap, tMiddle-tLength/2 &CR & \
               pX-tGap, tMiddle+tLength/2 &CR &CR & \
               pX+tGap, tMiddle-tLength/2 &CR & \
               pX+tGap, tMiddle+tLength/2 &CR 
         
         break
      case "long line"
         
         break
      default
         set the points of sIDDivider to \
               pX, the top of me + tOffset &CR & \
               pX, the bottom of me - tOffset
   end switch
   
end setDivider

on mouseDown
   if not  (the defaultCursor = 31 OR the defaultCursor = 30) then exit mouseDown
   if sIDDivider is empty then _init
   put true into sDragging -- signal we want to drag the dividers
end mouseDown

on mouseUp
   -- we don't want to drag anymore, signal this
   put false into sDragging
   set the defaultCursor to 0
end mouseUp

on mouseRelease
   -- if mouse is released (= mouseUp) outside of the bounds of the card
   mouseUp
end mouseRelease

on resizeControl_
   put "call to empty resizeControl_" & CR after msg
end resizeControl_

