-- ui system

ui = {}

function ui:draw()
  -- top bar
  rectfill(0, 0, 127, 8, 0)
  print("floor " .. game.floor, 2, 2, 13)

  -- hints
  local hint = self:get_hint()
  print(hint, 64 - #hint * 2, 2, 6)

  -- unit info panel (hovered)
  local u = cursor:get_unit()
  if u then
    rectfill(0, 112, 60, 127, 0)
    rect(0, 112, 60, 127, 13)
    print(u.name, 2, 114, u.col)
    print("hp:" .. u.hp .. "/" .. u.max_hp, 2, 120, 7)
  end

  -- selected unit panel
  if game.selected then
    local su = game.selected
    rectfill(68, 112, 127, 127, 0)
    rect(68, 112, 127, 127, 13)
    print(su.name, 70, 114, su.col)
    print("atk:" .. su.atk .. " def:" .. su.def, 70, 120, 7)
  end

  -- message
  if game.msg_timer > 0 then
    local w = #game.message * 4
    rectfill(62 - w/2, 58, 66 + w/2, 68, 0)
    print(game.message, 64 - w / 2, 60, 10)
  end
end

function ui:get_hint()
  if game.phase == "select" then
    local cu = cursor:get_unit()
    if cu and cu.team == "player" and cu.moved and not cu.acted then
      return "❎menu 🅾️undo"
    else
      return "❎sel/menu"
    end
  elseif game.phase == "move" then
    return "❎move 🅾️back"
  elseif game.phase == "action" then
    return "❎sel 🅾️back"
  elseif game.phase == "target" then
    return "❎target 🅾️back"
  elseif game.phase == "gameover" then
    return "❎retry"
  end
  return ""
end
