-- ui system

ui = {}

function ui:draw()
  -- top bar - dark purple gradient feel
  rectfill(0, 0, 127, 9, 0)
  rectfill(0, 9, 127, 9, 2)
  print("fLOOR " .. game.floor, 2, 2, 14)

  -- hints
  local hint = self:get_hint()
  print(hint, 64 - #hint * 2, 2, 13)

  -- unit info panel (hovered)
  local u = cursor:get_unit()
  if u then
    rectfill(0, 111, 62, 127, 0)
    rectfill(0, 111, 62, 112, 2)
    rect(0, 111, 62, 127, 2)
    print(u.name, 3, 114, u.col)
    print("hP:" .. u.hp .. "/" .. u.max_hp, 3, 121, 13)
  end

  -- selected unit panel
  if game.selected then
    local su = game.selected
    rectfill(65, 111, 127, 127, 0)
    rectfill(65, 111, 127, 112, 2)
    rect(65, 111, 127, 127, 2)
    print(su.name, 68, 114, su.col)
    print("aTK:" .. su.atk .. " dEF:" .. su.def, 68, 121, 13)
  end

  -- message - clean display for important messages only
  if game.msg_timer > 0 then
    local w = #game.message * 4
    rectfill(60 - w/2, 56, 68 + w/2, 70, 0)
    rect(60 - w/2, 56, 68 + w/2, 70, 2)
    print(game.message, 64 - w / 2, 60, 7)
  end
end

function ui:get_hint()
  if game.phase == "select" then
    local cu = cursor:get_unit()
    if cu and cu.team == "player" and cu.moved and not cu.acted then
      return "❎mENU 🅾️uNDO"
    else
      return "❎sEL/mENU"
    end
  elseif game.phase == "move" then
    return "❎mOVE 🅾️bACK"
  elseif game.phase == "action" then
    return "❎sEL 🅾️bACK"
  elseif game.phase == "target" then
    return "❎tARGET 🅾️bACK"
  elseif game.phase == "gameover" then
    return "❎rETRY"
  end
  return ""
end
