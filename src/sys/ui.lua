ui={}

-- helper for panels
local function draw_panel(x0,y0,x1,y1)
 rectfill(x0,y0,x1,y1,0)
 rectfill(x0,y0,x1,y0+1,2)
 rect(x0,y0,x1,y1,2)
end

function ui:draw()
 -- top bar
 rectfill(0,0,127,9,0)
 rectfill(0,9,127,9,2)
 print("fLOOR "..game.floor,2,2,14)

 -- hints
 local h=self:get_hint()
 print(h,64-#h*2,2,13)

 -- hovered unit/tile
 local u,c=cursor:get_unit(),cursor:get_tile()
 if u then
  draw_panel(0,111,62,127)
  print(u.name,3,114,u.team=="player" and 14 or 8)
  print("hP:"..u.hp.."/"..u.max_hp,3,121,13)
 elseif c then
  if c.type=="spawn" then
   draw_panel(0,111,62,127)
   print("sPAWN gATE",3,114,12)
   print("dEPLOY uNITS",3,121,13)
  elseif c.type=="goal" then
   draw_panel(0,111,62,127)
   print("eXIT gATE",3,114,9)
   print("tO nEXT fLOOR",3,121,13)
  end
 end

 -- selected unit
 local s=game.selected
 if s then
  draw_panel(65,111,127,127)
  print(s.name,68,114,14)
  print("aTK:"..s.atk.." dEF:"..s.def,68,121,13)
 end

 -- message
 if game.msg_timer>0 then
  local w=#game.message*4
  rectfill(60-w/2,56,68+w/2,70,0)
  rect(60-w/2,56,68+w/2,70,2)
  print(game.message,64-w/2,60,7)
 end
end

function ui:get_hint()
 local f=game.fsm.current
 local cu=cursor:get_unit()
 if f=="select" then
  if cu and cu.team=="player" and cu.moved and not cu.acted then return "❎mENU 🅾️uNDO" end
  return "❎sEL/mENU"
 elseif f=="move" then return "❎mOVE 🅾️bACK"
 elseif f=="action" then return "❎sEL 🅾️bACK"
 elseif f=="target" then return "❎tARGET 🅾️bACK"
 elseif f=="gameover" then return "❎rETRY" end
 return ""
end
