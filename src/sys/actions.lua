-- player actions

actions = {}

function actions:select_or_menu()
  local u = cursor:get_unit()
  local tile = cursor:get_tile()

  -- spawn tile without unit - show deploy menu
  if tile and tile.type == "spawn" and not u then
    self:show_deploy_menu()
    return
  end

  if u and u.team == "player" and not u.acted then
    if u.moved then
      -- unit has moved but not acted - show action menu
      game.selected = u
      self:show_action_menu()
      sfx(1)
    else
      -- unit hasn't moved - show move tiles
      game.selected = u
      game.move_tiles = movement:calc_tiles(u)
      game.phase = "move"
      bindings:bind_move()
      sfx(1)
    end
  else
    -- no unit or unit already acted - show menu without unit actions
    game.selected = nil
    self:show_action_menu()
  end
end

function actions:show_deploy_menu()
  game.phase = "deploy_menu"
  local items = {}

  for u in all(units.list) do
    if u.team == "player" and not u.deployed then
      add(items, {
        label = u.name,
        unit = u,
        action = function()
          game.deploy_menu:hide()
          game.deploy_menu = nil
          self:deploy_unit(u)
        end
      })
    end
  end

  if #items == 0 then
    game.phase = "select"
    bindings:bind_select()
    return
  end

  game.deploy_menu = menu:new(items, {x = 80, y = 16})
  game.deploy_menu:show()
  bindings:bind_deploy_menu()
end

function actions:deploy_unit(u)
  u.x, u.y = grid.spawn_x, grid.spawn_y
  u.tx, u.ty = grid.spawn_x, grid.spawn_y
  u.deployed = true
  u.moved = true
  u.orig_x, u.orig_y = -1, -1

  game.selected = u
  game.move_tiles = movement:calc_tiles(u)
  game.phase = "move"
  bindings:bind_move()
  sfx(1)
end

function actions:show_action_menu()
  local u = game.selected
  game.phase = "action"

  local items = {}

  -- check if unit already has a queued action
  local has_queued_action = false
  for action in all(game.action_queue) do
    if action.attacker == u then
      has_queued_action = true
      break
    end
  end

  -- unit-specific actions
  if u and not u.acted and not has_queued_action then
    game.attack_tiles = movement:calc_attack_tiles(u, u.x, u.y)

    -- check for valid targets
    local has_target = false
    for t in all(game.attack_tiles) do
      local target = units:at(t.x, t.y)
      if target and target.team == "enemy" then
        has_target = true
        break
      end
    end

    local tile = grid:get_tile(u.x, u.y)
    local on_goal = tile and tile.type == "goal"

    if on_goal then
      add(items, {label = "escape!", action = function()
        game.action_menu:hide()
        game.action_menu = nil
        game.selected = nil
        game.attack_tiles = {}
        game:next_floor()
      end})
    end

    add(items, {label = "attack", action = function()
      game.action_menu:hide()
      game.action_menu = nil
      game.phase = "target"
      self:cycle_target(0)
      bindings:bind_target()
    end, enabled = function()
      return has_target
    end})

    add(items, {label = "wait", action = function()
      game.action_menu:hide()
      game.action_menu = nil
      game.selected = nil
      game.attack_tiles = {}
      game.phase = "select"
      bindings:bind_select()
    end})
  end

  -- general actions
  add(items, {label = function()
    return "execute (" .. #game.action_queue .. ")"
  end, action = function()
    game.action_menu:hide()
    game.action_menu = nil
    game.selected = nil
    game.attack_tiles = {}
    game:execute_turn()
  end, enabled = function()
    return #game.action_queue > 0
  end})

  add(items, {label = "end turn", action = function()
    game.action_menu:hide()
    game.action_menu = nil
    game.selected = nil
    game.attack_tiles = {}
    game:execute_and_end_turn()
  end})

  add(items, {label = "options", action = function()
    game.options_menu:show()
    bindings:bind_options_menu()
  end})

  -- create options submenu
  game.options_menu = menu:new({
    {label = function()
      return "cam: " .. (camera.cam_left and "left" or "right")
    end, action = function()
      camera.cam_left = not camera.cam_left
    end}
  }, {x = 90, y = 26})

  game.action_menu = menu:new(items, {x = 80, y = 16})
  game.action_menu:show()
  bindings:bind_action_menu()
end

function actions:confirm_move()
  if not grid:tile_in_list(cursor.x, cursor.y, game.move_tiles) then
    return
  end

  local u = game.selected
  u.x = cursor.x
  u.y = cursor.y
  u.moved = true
  game.move_tiles = {}

  tween:cancel_all(u)
  tween:new(u, {tx = u.x, ty = u.y}, 10, {ease = tween.ease.out_quad})
  self:show_action_menu()
  sfx(1)
end

function actions:cancel_move()
  game.selected = nil
  game.move_tiles = {}
  game.phase = "select"
  bindings:bind_select()
  sfx(0)
end

function actions:cancel_action()
  game.action_menu:hide()
  game.action_menu = nil
  game.attack_tiles = {}
  game.selected = nil
  game.phase = "select"
  bindings:bind_select()
  sfx(0)
end

function actions:cycle_target(dir)
  local targets = movement:get_valid_targets(game.attack_tiles)
  if #targets == 0 then return end

  -- find current target index
  local cur_idx = 1
  for i, t in ipairs(targets) do
    if t.x == cursor.x and t.y == cursor.y then
      cur_idx = i
      break
    end
  end

  -- cycle to next/prev
  local new_idx = ((cur_idx - 1 + dir) % #targets) + 1
  cursor.x = targets[new_idx].x
  cursor.y = targets[new_idx].y
  camera:center(cursor.x, cursor.y)
  sfx(0)
end

function actions:confirm_target()
  if not grid:tile_in_list(cursor.x, cursor.y, game.attack_tiles) then
    return
  end

  local target = units:at(cursor.x, cursor.y)
  if not target then return end

  local u = game.selected
  add(game.action_queue, {
    attacker = u,
    target = target,
    type = "attack"
  })

  game.selected = nil
  game.attack_tiles = {}
  game.phase = "select"
  bindings:bind_select()
  sfx(1)
end

function actions:cancel_target()
  self:show_action_menu()
  sfx(0)
end

function actions:try_undo_move()
  local u = cursor:get_unit()

  if u and u.team == "player" and u.moved and not u.acted then
    -- check if original position is now occupied by another unit
    if u.orig_x != -1 and u.orig_y != -1 then
      local blocker = units:at(u.orig_x, u.orig_y)
      if blocker and blocker != u then
        -- can't undo - someone else is there now
        sfx(0)
        return
      end
    end

    -- remove queued attacks for this unit
    for i = #game.action_queue, 1, -1 do
      if game.action_queue[i].attacker == u then
        deli(game.action_queue, i)
      end
    end

    if u.orig_x == -1 and u.orig_y == -1 then
      -- unit was just deployed - undeploy
      u.deployed = false
      u.x, u.y = -1, -1
      u.tx, u.ty = -1, -1
      u.moved = false
      sfx(0)
    else
      -- return to original position
      u.x = u.orig_x
      u.y = u.orig_y
      u.moved = false
      tween:cancel_all(u)
      tween:new(u, {tx = u.x, ty = u.y}, 10, {ease = tween.ease.out_quad})
      sfx(0)
    end
  end
end
