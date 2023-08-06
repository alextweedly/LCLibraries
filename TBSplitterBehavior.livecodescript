script "TBSplitterBehavior"
-- behavior stack for the Top-Bottom splitter

-- splits to a top and a bottom part

##############################
-- resizing of splitter pane, adjusting geometry

-- TODO extend uAdjust to allow relative adjustments?!?

---- splits to a top and a bottom part

##############################
-- resizing of splitter pane, adjusting geometry
local sDragging
local sHiddenTop, sHiddenBottom, sLastTopheightFraction
local sIDDivider, sIDTop, sIDBottom

private command _init
   local tIDs, tmp
   put  the childControlIDs of me into tIDs
   try
      put the long id of control id line 2 of tIDs into sIDTop
      put the long id of control id line 3 of tIDs into sIDBottom
      put the long id of control id line 4 of tIDs into sIDDivider
      
      if the short name of sIDTop begins with "T_" AND \
            the short name of sIDBottom begins with "B_" AND \
            the short name of sIDDivider = "Divider" then
         exit _init
      end if
   catch tmp
   end try
   
   put "Bad group contents" &CR after msg
   put empty into sIDDivider
   put empty into sIDTop
   put empty into sIDBottom
   
end _init

on hideTop
   if sHiddenBottom OR sHiddenTop then
      -- cannot hide both, or already hidden
      exit hideTop
   end if
   if sIDDivider is empty then _init
   
   put TRUE into sHiddenTop
   put the height of sIDTop / the height of me into sLastTopHeightFraction
   set the vis of sIDTop to FALSE
   
   set the height of sIDBottom to the height of me
   set the bottom of sIDBottom to the bottom of me
   send "resizecontrol" to me
   
end hideTop

on showTop pHowMuch
   if sIDDivider is empty then _init
   
   -- always do this, so it can either show it after hiding, or change width
   put FALSE into sHiddenTop
   local tHT, tHB
   if pHowMuch is a number then
      if pHowMuch <= 1 then
         put pHowMuch into sLastTopHeightFraction
      else
         put pHowMuch / the width of me into sLastTopHeightFraction
      end if
   end if
   put  the height of me * sLastTopheightFraction into tHT
   put the height of me - tHT into tHB
   
   set the height of sIDTop to tHT
   set the Top of sIDTop to the top of me
   
   set the height of sIDBottom to tHB
   set the bottom of sIDBottom to the Bottom of me
   set the vis of sIDTop to TRUE
   send "resizecontrol" to me

end showTop

on hideBottom
   if sHiddenBottom OR sHiddenTop then
      -- cannot hide both, or already hidden
      exit hideBottom
   end if
   
   if sIDDivider is empty then _init
   put TRUE into sHiddenBottom
   put the height of sIDTop / the height of me into sLastTopHeightFraction
   set the vis of sIDBottom to FALSE
   
   set the height of sIDTop to the height of me
   set the top of sIDTop to the top of me
   send "resizecontrol" to me
   
end hideBottom

on showBottom pHowMuch
   if sIDDivider is empty then _init
   
   put FALSE into sHiddenBottom
   local tHT, tHB
   
   if pHowMuch is a number then
      if pHowMuch <= 1 then
         put 1-pHowMuch into sLastTopHeightFraction
      else
         put 1 - (pHowMuch / the height of me) into sLastTopHeightFraction
      end if
   end if
   
   put the height of me * sLastTopHeightFraction into tHT
   put the height of me - tHT into tHB
   
   set the height of sIDTop to tHT
   set the top of sIDTop to the top of me
   
   set the height of sIDBottom to tHB
   set the bottom of sIDBottom to the bottom of me
   set the vis of sIDBottom to TRUE
   send "resizecontrol" to me

end showBottom

on mouseMove x,y
   if sIDDivider is empty then _init
   
   if sDragging then -- now we change sizes of the panes
      if the mouse is not down then
         set the defaultCursor to 0
         exit mouseMove
      end if
      lock screen
      local tNewheightForTop, tNewheightForBottom
      
      put y - the Top of me into tNewheightForTop
      
      -- catch for mouse <> min of Top pane
      if tNewheightForTop < the uMinTop of me then 
         put the uMinTop of me into tNewheightForTop
      end if
      
      if the uMinTop of me + the uMinBottom of me > the height of me then
         -- we cannot fit both min sizes, just accept Bottom pane narrower
         put the height of me - tNewHeightForTop into tNewheightForBottom
      else 
         put the height of me - tNewheightForTop into tNewheightForBottom
         if tNewheightForBottom < the uMinBottom of me then
            put the uMinBottom of me into tNewheightForBottom
            put the height of me - tNewheightForBottom into tNewheightForTop
         end if
      end if
      
      set the height of sIDBottom to tNewheightForBottom
      set the bottom of sIDBottom to the bottom of me
      
      set the height of sIDTop to tNewheightForTop
      set the top of sIDTop to the top of me
      
      setDivider the top of me + tNewheightForTop
      
      unlock screen
      -- end changing sizes of the panes
      
   else
      -- not dragging, default testing if over a divider line 
      local tDividerY
      put (the top of sIDDivider + the bottom of sIDDivider) / 2 into tDividerY
      
      -- if we are over a divider then change cursor   
      local tOffset, tSensitivity
      put the uDividerOffset of me into tOffset
      if tOffset is empty then put 4 into tOffset
      put the uDividerSensitivity of me into tSensitivity
      if tSensitivity is empty then put 2 into tSensitivity
      
      if (y > tDividerY - tSensitivity and y < tDividerY + tSensitivity) AND \
            (x > the left of me + tOffset  and x < the right of me - tOffset) then
         set the defaultcursor to 30
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
   
   local tRme, tRTop, tRBottom, tX1, tX2
   put the rect of me into tRme
   
   set the rect of grc "Backdrop" of me to tRme
   switch
      case sHiddenTop  
         set the rect of sIDBottom to tRme
         setDivider the Top of me
         break
      case sHiddenBottom
         set the rect of sIDTop to tRme
         setDivider the Bottom of me
         break
      default
         put the rect of sIDTop into tRTop
         put the rect of sIDBottom into tRBottom
         put item 1 of tRme into tX1
         put item 3 of tRme into tX2
         
         put tX1 into item 1 of tRTop
         put tX1 into item 1 of tRBottom
         put tX2 into item 3 of tRTop
         put tX2 into item 3 of tRBottom
         
         local tDiffTop, tDiffBottom, tRatio, tHT, tHB
         put item 4 of tRTop - item 2 of tRTop into tHT
         put item 4 of tRBottom - item 2 of tRBottom into tHB
         
         -- does this change affect L, or R or borh ?
         switch the uAdjust of me
            case "Top only"
               set the rect of sIDBottom to\
                     tX1, the bottom of me - tHB, tX2, the bottom of me
               set the rect of sIDTop to\
                     tX1, the top of me, tX2, the bottom of me - tHB
               setDivider the bottom of me - tHB
               break
            case "Bottom only"
               set the rect of sIDTop to\
                     tX1, the top of me, tX2, the Top of me + tHT
               set the rect of sIDBottom to\
                     tX1, the top of me + tHT, tX2, the bottom of me
               setDivider the top of me + tHT
               break
            case "both"
            default
               put tHT / (tHT + tHB) into tRatio
               put round(the height of me * tRatio) into tHT
               set the rect of sIDTop to\
                     tX1, the top of me, tX2, the top of me + tHT
               set the rect of sIDBottom to\
                     tX1, the top of me + tHT, tX2, the bottom of me
               setDivider the top of me + tHT
               break
         end switch
   end switch
end resizeControl

on setDivider pY
   local tOffset
   put the uDividerOffset of me into tOffset
   if tOffset is empty then put 4 into tOffset
   
   if sIDDivider is empty then _init
   set the points of sIDDivider to \
         the left of me + tOffset, pY &CR & \
         the right of me - tOffset, pY
   
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

