
----------
-- game
----------

game = {
  -- camera
  cam_x = 0,
  cam_y = -20,
  cam_rot = 0,
  cam_rot_tween = 0,
  zoom = 2,
  zoom_tween = 2,
  zoom_levels = {1, 1.5, 2},
  zooming = false,
  grid_w = 8,
  grid_h = 8,
  tile_w = 16,
  tile_h = 8,
  floor = 1,
  phase = "select",
  cursor = {x = 0, y = 0},
  selected = nil,
  move_tiles = {},
  attack_tiles = {},
  action_queue = {},
  message = "",
  msg_timer = 0,
  cam_left = false
}

function game:init()
  self.units = {}
  self.tiles = {}

  add(self.units, {
    name = "vex",
    team = "player",
    hp = 20, max_hp = 20,
    atk = 5, def = 2, spd = 10,
    move = 3, range = 1,
    col = 8,
    x = -1, y = -1,
    tx = -1, ty = -1,
    deployed = false,
    acted = false,
    moved = false
  })

  add(self.units, {
    name = "nyx",
    team = "player",
    hp = 12, max_hp = 12,
    atk = 8, def = 0, spd = 8,
    move = 3, range = 2,
    col = 14,
    x = -1, y = -1,
    tx = -1, ty = -1,
    deployed = false,
    acted = false,
    moved = false
  })

  self:generate_floor()
  self:spawn_enemies()

  self.cursor.x = self.spawn_x
  self.cursor.y = self.spawn_y
  self:center_camera(self.spawn_x, self.spawn_y, true)
  self:start_player_phase()
end

function game:generate_floor()
  self.tiles = {}
  for y = 0, self.grid_h - 1 do
    self.tiles[y] = {}
    for x = 0, self.grid_w - 1 do
      local h = 0
      local r = rnd()
      if r > 0.4 then
        h = 1
      end
      if r > 0.75 then
        h = 2
      end
      self.tiles[y][x] = {
        height = h,
        col = ({1, 2, 13})[h + 1], -- dark blue, dark purple, lavender
        type = "normal"
      }
    end
  end

  self.spawn_x = flr(rnd(self.grid_w))
  self.spawn_y = flr(rnd(self.grid_h))
  self.tiles[self.spawn_y][self.spawn_x].height = 0
  self.tiles[self.spawn_y][self.spawn_x].col = 1  -- dark blue base
  self.tiles[self.spawn_y][self.spawn_x].type = "spawn"

  local gx, gy
  repeat
    gx = flr(rnd(self.grid_w))
    gy = flr(rnd(self.grid_h))
  until (gx != self.spawn_x or gy != self.spawn_y) and
        (abs(gx - self.spawn_x) + abs(gy - self.spawn_y) >= 4)

  self.tiles[gy][gx].height = 0
  self.tiles[gy][gx].col = 2  -- dark red/maroon base
  self.tiles[gy][gx].type = "goal"
  self.goal_x, self.goal_y = gx, gy

  for u in all(self.units) do
    if u.team == "player" then
      u.deployed = false
      u.x, u.y = -1, -1
      u.tx, u.ty = -1, -1
    end
  end
end

function game:spawn_unit(x, y, data)
  local unit = {
    x = x, y = y,
    tx = x, ty = y,
    acted = false,
    moved = false
  }
  for k, v in pairs(data) do
    unit[k] = v
  end
  add(self.units, unit)
  return unit
end

function game:spawn_enemies()
  local count = 2 + flr(self.floor / 2)
  for i = 1, count do
    local x, y
    repeat
      x = flr(rnd(self.grid_w))
      y = flr(rnd(self.grid_h))
    until not self:unit_at(x, y) and
          not (x == self.spawn_x and y == self.spawn_y) and
          not (x == self.goal_x and y == self.goal_y)

    self:spawn_unit(x, y, {
      name = "imp",
      team = "enemy",
      hp = 5 + self.floor * 2,
      max_hp = 5 + self.floor * 2,
      atk = 2 + flr(self.floor / 2),
      def = 0, spd = 6,
      move = 2, range = 1,
      col = 12  -- light blue for imps
    })
  end
end

function game:unit_at(x, y)
  for u in all(self.units) do
    if u.x == x and u.y == y then return u end
  end
end

function game:start_player_phase()
  self.phase = "select"
  self.selected = nil
  self.move_tiles = {}
  self.attack_tiles = {}
  self.options_menu = nil
  self.action_menu = nil
  self.deploy_menu = nil

  for u in all(self.units) do
    if u.team == "player" then
      u.acted = false
      u.moved = false
      if u.deployed then
        u.orig_x = u.x
        u.orig_y = u.y
      else
        u.orig_x = -1
        u.orig_y = -1
      end
    end
  end

  self:msg("player phase")
  self:bind_select()
end

function game:bind_select()
  self.did_rotate = false
  self.did_zoom = false
  input:bind({
    [0] = function()
      if btn(4) then
        self:rotate_camera(1)
        self.did_rotate = true
      else
        self:move_cursor(-1, 0)
      end
    end,
    [1] = function()
      if btn(4) then
        self:rotate_camera(-1)
        self.did_rotate = true
      else
        self:move_cursor(1, 0)
      end
    end,
    [2] = function()
      if btn(4) then
        self:change_zoom(1)
        self.did_zoom = true
      else
        self:move_cursor(0, -1)
      end
    end,
    [3] = function()
      if btn(4) then
        self:change_zoom(-1)
        self.did_zoom = true
      else
        self:move_cursor(0, 1)
      end
    end,
    [4] = function()
      if not self.did_rotate and not self.did_zoom then
        self:try_undo_move()
      end
      self.did_rotate = false
      self.did_zoom = false
    end,
    [5] = function() self:select_or_menu() end
  })
end

function game:change_zoom(dir)
  if self.zooming then return end
  local new_zoom = self.zoom + dir
  if new_zoom < 1 or new_zoom > 3 then return end

  self.zooming = true
  self.zoom = new_zoom

  tween:new(self, {zoom_tween = new_zoom}, 15, {
    ease = tween.ease.out_quad,
    on_complete = function()
      self.zooming = false
    end
  })

  local target = self:calc_camera_pos(self.cursor.x, self.cursor.y, self.cam_rot_tween, new_zoom)
  tween:cancel_all(self.cam_tween_target or {})
  self.cam_tween_target = {x = self.cam_x, y = self.cam_y}
  tween:new(self.cam_tween_target, {x = target.x, y = target.y}, 15, {
    ease = tween.ease.out_quad
  })
  sfx(0)
end

function game:rotate_camera(dir)
  if self.rotating then return end
  self.rotating = true
  local target = (self.cam_rot + dir) % 4
  if target < 0 then target = target + 4 end
  local tween_target = self.cam_rot + dir
  local final_cam = self:calc_camera_pos(self.cursor.x, self.cursor.y, tween_target)

  tween:cancel_all(self.cam_tween_target or {})
  self.cam_tween_target = {x = self.cam_x, y = self.cam_y}

  tween:new(self, {cam_rot_tween = tween_target}, 15, {
    ease = tween.ease.out_quad,
    on_complete = function()
      self.cam_rot = target
      self.cam_rot_tween = target
      self.rotating = false
    end
  })

  tween:new(self.cam_tween_target, {x = final_cam.x, y = final_cam.y}, 15, {
    ease = tween.ease.out_quad
  })
  sfx(0)
end

function game:calc_camera_pos(x, y, rot, zoom)
  zoom = zoom or self.zoom
  local z = self.zoom_levels[zoom]
  local cx, cy = self.grid_w / 2, self.grid_h / 2

  local rx, ry = x - cx, y - cy
  local angle = rot * 0.25
  local cos_a, sin_a = cos(angle), sin(angle)
  local nx = rx * cos_a - ry * sin_a
  local ny = rx * sin_a + ry * cos_a
  rx, ry = nx + cx, ny + cy

  local sx = (rx - ry) * (self.tile_w / 2) * z + 64
  local sy = (rx + ry) * (self.tile_h / 2) * z + 32

  return {x = 64 - sx, y = 64 - sy}
end

function game:try_undo_move()
  local u = self:unit_at(self.cursor.x, self.cursor.y)
  if u and u.team == "player" and u.moved and not u.acted then
    for i = #self.action_queue, 1, -1 do
      if self.action_queue[i].attacker == u then
        deli(self.action_queue, i)
      end
    end

    if u.orig_x == -1 and u.orig_y == -1 then
      u.deployed = false
      u.x, u.y = -1, -1
      u.tx, u.ty = -1, -1
      u.moved = false
      sfx(0)
      self:msg("unit returned")
    else
      u.x = u.orig_x
      u.y = u.orig_y
      u.moved = false
      tween:cancel_all(u)
      tween:new(u, {tx = u.x, ty = u.y}, 10, {ease = tween.ease.out_quad})
      sfx(0)
      self:msg("move undone")
    end
  end
end

function game:select_or_menu()
  local u = self:unit_at(self.cursor.x, self.cursor.y)
  local tile = self.tiles[self.cursor.y] and self.tiles[self.cursor.y][self.cursor.x]

  if tile and tile.type == "spawn" and not u then
    self:show_deploy_menu()
    return
  end

  if u and u.team == "player" and not u.acted then
    if u.moved then
      -- unit has moved but not acted - show unified menu with unit actions
      self.selected = u
      self:show_action_menu()
      sfx(1)
    else
      -- unit hasn't moved - show move tiles
      self.selected = u
      self:calc_move_tiles(u)
      self.phase = "move"
      self:bind_move()
      sfx(1)
    end
  else
    -- no unit or unit already acted - show menu without unit actions
    self.selected = nil
    self:show_action_menu()
  end
end

function game:show_deploy_menu()
  self.phase = "deploy_menu"
  local items = {}
  for u in all(self.units) do
    if u.team == "player" and not u.deployed then
      add(items, {
        label = u.name,
        unit = u,
        action = function()
          self.deploy_menu:hide()
          self.deploy_menu = nil
          self:deploy_unit(u)
        end
      })
    end
  end

  if #items == 0 then
    self.phase = "select"
    self:bind_select()
    return
  end

  self.deploy_menu = menu:new(items, {x = 80, y = 16})
  self.deploy_menu:show()
  self:bind_deploy_menu()
end

function game:bind_deploy_menu()
  input:bind({
    [2] = function()
      if self.deploy_menu then self.deploy_menu:nav(-1) end
    end,
    [3] = function()
      if self.deploy_menu then self.deploy_menu:nav(1) end
    end,
    [4] = function()
      if self.deploy_menu then
        self.deploy_menu:hide()
        self.deploy_menu = nil
      end
      self.phase = "select"
      self:bind_select()
      sfx(0)
    end,
    [5] = function()
      if self.deploy_menu then self.deploy_menu:select() end
    end
  })
end

function game:deploy_unit(u)
  u.x, u.y = self.spawn_x, self.spawn_y
  u.tx, u.ty = self.spawn_x, self.spawn_y
  u.deployed = true
  u.moved = true
  u.orig_x, u.orig_y = -1, -1

  self.selected = u
  self:calc_move_tiles(u)
  self.phase = "move"
  self:bind_move()
  sfx(1)
end

function game:bind_options_menu()
  input:bind({
    [2] = function()
      if self.options_menu then self.options_menu:nav(-1) end
    end,
    [3] = function()
      if self.options_menu then self.options_menu:nav(1) end
    end,
    [4] = function()
      if self.options_menu then
        self.options_menu:hide()
        self.options_menu = nil
      end
      self:bind_ground_menu()
      sfx(0)
    end,
    [5] = function()
      if self.options_menu then self.options_menu:select() end
    end
  })
end

function game:bind_move()
  input:bind({
    [0] = function() self:move_cursor(-1, 0) end,
    [1] = function() self:move_cursor(1, 0) end,
    [2] = function() self:move_cursor(0, -1) end,
    [3] = function() self:move_cursor(0, 1) end,
    [4] = function() self:cancel_move() end,
    [5] = function() self:confirm_move() end
  })
end

function game:bind_action_menu()
  input:bind({
    [2] = function() self.action_menu:nav(-1) end,
    [3] = function() self.action_menu:nav(1) end,
    [4] = function() self:cancel_action() end,
    [5] = function() self.action_menu:select() end
  })
end

function game:bind_target()
  input:bind({
    [0] = function() self:cycle_target(-1) end,
    [1] = function() self:cycle_target(1) end,
    [2] = function() self:cycle_target(-1) end,
    [3] = function() self:cycle_target(1) end,
    [4] = function() self:cancel_target() end,
    [5] = function() self:confirm_target() end
  })
end

function game:get_valid_targets()
  local targets = {}
  for t in all(self.attack_tiles) do
    local unit = self:unit_at(t.x, t.y)
    if unit and unit.team == "enemy" then
      add(targets, {x = t.x, y = t.y, unit = unit})
    end
  end
  return targets
end

function game:cycle_target(dir)
  local targets = self:get_valid_targets()
  if #targets == 0 then return end

  -- find current target index
  local cur_idx = 1
  for i, t in ipairs(targets) do
    if t.x == self.cursor.x and t.y == self.cursor.y then
      cur_idx = i
      break
    end
  end

  -- cycle to next/prev
  local new_idx = ((cur_idx - 1 + dir) % #targets) + 1
  self.cursor.x = targets[new_idx].x
  self.cursor.y = targets[new_idx].y
  self:center_camera(self.cursor.x, self.cursor.y)
  sfx(0)
end

function game:move_cursor(dx, dy)
  local gx, gy = 0, 0
  local rot = self.cam_rot
  for i = 1, rot do
    dx, dy = -dy, dx
  end

  if self.cam_left then
    gx, gy = dx, dy
  else
    gx = dy
    gy = -dx
  end

  self.cursor.x = mid(0, self.cursor.x + gx, self.grid_w - 1)
  self.cursor.y = mid(0, self.cursor.y + gy, self.grid_h - 1)
  self:center_camera(self.cursor.x, self.cursor.y)
  sfx(0)
end

function game:calc_move_tiles(unit)
  self.move_tiles = {}
  add(self.move_tiles, {x = unit.x, y = unit.y})

  local start_h = self.tiles[unit.y][unit.x].height
  local visited = {}
  local queue = {{x = unit.x, y = unit.y, cost = 0}}

  -- 8 directions: cardinal + diagonal
  local dirs = {
    {-1, 0}, {1, 0}, {0, -1}, {0, 1},
    {-1, -1}, {-1, 1}, {1, -1}, {1, 1}
  }

  while #queue > 0 do
    local best_i = 1
    for i = 2, #queue do
      if queue[i].cost < queue[best_i].cost then
        best_i = i
      end
    end
    local cur = deli(queue, best_i)

    local key = cur.x .. "," .. cur.y
    if not visited[key] then
      visited[key] = true

      if cur.x != unit.x or cur.y != unit.y then
        local other = self:unit_at(cur.x, cur.y)
        if not other then
          add(self.move_tiles, {x = cur.x, y = cur.y})
        end
      end

      for _, dir in pairs(dirs) do
        local nx, ny = cur.x + dir[1], cur.y + dir[2]
        if nx >= 0 and nx < self.grid_w and ny >= 0 and ny < self.grid_h then
          local nkey = nx .. "," .. ny
          if not visited[nkey] then
            local cur_h = self.tiles[cur.y][cur.x].height
            local next_h = self.tiles[ny][nx].height
            local h_diff = abs(next_h - cur_h)

            -- diagonal movement costs 1 (same as cardinal) but still affected by height
            local move_cost = 1 + h_diff
            local new_cost = cur.cost + move_cost

            if new_cost <= unit.move then
              add(queue, {x = nx, y = ny, cost = new_cost})
            end
          end
        end
      end
    end
  end
end

function game:calc_attack_tiles(unit, from_x, from_y)
  self.attack_tiles = {}
  for dy = -unit.range, unit.range do
    for dx = -unit.range, unit.range do
      if abs(dx) + abs(dy) <= unit.range and (dx != 0 or dy != 0) then
        local tx, ty = from_x + dx, from_y + dy
        if tx >= 0 and tx < self.grid_w and ty >= 0 and ty < self.grid_h then
          add(self.attack_tiles, {x = tx, y = ty})
        end
      end
    end
  end
end

function game:tile_in_list(x, y, list)
  for t in all(list) do
    if t.x == x and t.y == y then return true end
  end
  return false
end

function game:confirm_move()
  if not self:tile_in_list(self.cursor.x, self.cursor.y, self.move_tiles) then
    return
  end

  local u = self.selected
  u.x = self.cursor.x
  u.y = self.cursor.y
  u.moved = true
  self.move_tiles = {}

  tween:cancel_all(u)
  tween:new(u, {tx = u.x, ty = u.y}, 10, {ease = tween.ease.out_quad})
  self:show_action_menu()
  sfx(1)
end

function game:cancel_move()
  self.selected = nil
  self.move_tiles = {}
  self.phase = "select"
  self:bind_select()
  sfx(0)
end

function game:show_action_menu()
  local u = self.selected
  self.phase = "action"

  local items = {}

  -- unit-specific actions (if a unit is selected and hasn't acted)
  if u and not u.acted then
    self:calc_attack_tiles(u, u.x, u.y)

    -- check if any enemies are in attack range
    local has_target = false
    for t in all(self.attack_tiles) do
      local target = self:unit_at(t.x, t.y)
      if target and target.team == "enemy" then
        has_target = true
        break
      end
    end

    local on_goal = self.tiles[u.y] and self.tiles[u.y][u.x] and self.tiles[u.y][u.x].type == "goal"

    if on_goal then
      add(items, {label = "escape!", action = function()
        self.action_menu:hide()
        self.action_menu = nil
        self.selected = nil
        self.attack_tiles = {}
        self:next_floor()
      end})
    end

    add(items, {label = "attack", action = function()
      self.action_menu:hide()
      self.action_menu = nil
      self.phase = "target"
      self:cycle_target(0)
      self:bind_target()
    end, enabled = function()
      return has_target
    end})

    add(items, {label = "wait", action = function()
      self.action_menu:hide()
      self.action_menu = nil
      self.selected = nil
      self.attack_tiles = {}
      self.phase = "select"
      self:bind_select()
    end})
  end

  -- general actions (always available)
  add(items, {label = function()
    return "execute (" .. #self.action_queue .. ")"
  end, action = function()
    self.action_menu:hide()
    self.action_menu = nil
    self.selected = nil
    self.attack_tiles = {}
    self:execute_turn()
  end, enabled = function()
    return #self.action_queue > 0
  end})

  add(items, {label = "end turn", action = function()
    self.action_menu:hide()
    self.action_menu = nil
    self.selected = nil
    self.attack_tiles = {}
    self:execute_and_end_turn()
  end})

  add(items, {label = "options", action = function()
    self.options_menu:show()
    self:bind_options_menu()
  end})

  self.options_menu = menu:new({
    {label = function()
      return "cam: " .. (self.cam_left and "left" or "right")
    end, action = function()
      self.cam_left = not self.cam_left
    end}
  }, {x = 90, y = 26})

  self.action_menu = menu:new(items, {x = 80, y = 16})
  self.action_menu:show()
  self:bind_action_menu()
end

function game:cancel_action()
  self.action_menu:hide()
  self.action_menu = nil
  self.attack_tiles = {}
  self.selected = nil
  self.phase = "select"
  self:bind_select()
  sfx(0)
end

function game:confirm_target()
  if not self:tile_in_list(self.cursor.x, self.cursor.y, self.attack_tiles) then
    return
  end

  local target = self:unit_at(self.cursor.x, self.cursor.y)
  if not target then
    return
  end

  local u = self.selected
  add(self.action_queue, {
    attacker = u,
    target = target,
    type = "attack"
  })

  self.selected = nil
  self.attack_tiles = {}
  self.phase = "select"
  self:bind_select()
  self:msg("attack queued!")
  sfx(1)
end

function game:cancel_target()
  self:show_action_menu()
  sfx(0)
end

function game:execute_turn()
  if #self.action_queue == 0 then
    self.phase = "select"
    self:bind_select()
    return
  end

  for u in all(self.units) do
    if u.team == "player" and u.moved then
      u.acted = true
    end
  end

  self.phase = "execute"
  self.end_turn_after_execute = false
  input:clear()
  self:process_next_action()
end

function game:execute_and_end_turn()
  for u in all(self.units) do
    if u.team == "player" and u.moved then
      u.acted = true
    end
  end

  if #self.action_queue == 0 then
    self:start_enemy_phase()
    return
  end

  self.phase = "execute"
  self.end_turn_after_execute = true
  input:clear()
  self:process_next_action()
end

function game:process_next_action()
  if #self.action_queue == 0 then
    if self.end_turn_after_execute then
      self:start_enemy_phase()
    else
      self.phase = "select"
      self:bind_select()
    end
    return
  end

  local action = deli(self.action_queue, 1)
  if action.type == "attack" then
    self:do_attack(action.attacker, action.target, function()
      self:process_next_action()
    end)
  end
end

function game:do_attack(attacker, target, on_done)
  local atk_h = self.tiles[attacker.y] and self.tiles[attacker.y][attacker.x]
  atk_h = atk_h and atk_h.height or 0
  local def_h = self.tiles[target.y] and self.tiles[target.y][target.x]
  def_h = def_h and def_h.height or 0

  local height_diff = atk_h - def_h
  local height_atk_bonus = max(0, height_diff * 2)
  local height_def_bonus = max(0, -height_diff * 1)

  local chain_bonus = 0
  for u in all(self.units) do
    if u != attacker and u.team == attacker.team then
      local dist = abs(u.x - target.x) + abs(u.y - target.y)
      if dist <= u.range then
        chain_bonus += flr(u.atk / 2)
      end
    end
  end

  local total_atk = attacker.atk + chain_bonus + height_atk_bonus
  local total_def = target.def + height_def_bonus
  local dmg = max(1, total_atk - total_def)

  local ox, oy = attacker.tx, attacker.ty
  local dx = (target.x - attacker.x) * 0.3
  local dy = (target.y - attacker.y) * 0.3

  tween:new(attacker, {tx = ox + dx, ty = oy + dy}, 6, {
    ease = tween.ease.out_quad,
    on_complete = function()
      target.hp -= dmg
      sfx(2)

      local msg = dmg .. " dmg!"
      if chain_bonus > 0 then msg = msg .. " chain+" end
      if height_diff > 0 then msg = msg .. " high+"
      elseif height_diff < 0 then msg = msg .. " low-" end
      self:msg(msg)

      tween:new(attacker, {tx = ox, ty = oy}, 8, {
        ease = tween.ease.out_back,
        on_complete = function()
          local transitioned = self:check_dead()
          if not transitioned and on_done then
            on_done()
          end
        end
      })
    end
  })
end

function game:check_dead()
  for u in all(self.units) do
    if u.hp <= 0 then
      del(self.units, u)
      sfx(3)
    end
  end

  local players, enemies = 0, 0
  for u in all(self.units) do
    if u.team == "player" then players += 1
    else enemies += 1 end
  end

  if enemies == 0 then
    self:next_floor()
    return true
  elseif players == 0 then
    self:game_over()
    return true
  end
  return false
end

function game:start_enemy_phase()
  self.phase = "enemy"
  self:msg("enemy phase")

  local enemies = {}
  for u in all(self.units) do
    if u.team == "enemy" then add(enemies, u) end
  end

  self.enemy_queue = enemies
  self:process_next_enemy()
end

function game:process_next_enemy()
  if #self.enemy_queue == 0 then
    self:start_player_phase()
    return
  end

  local enemy = deli(self.enemy_queue, 1)

  local closest, closest_dist = nil, 999
  for u in all(self.units) do
    if u.team == "player" then
      local d = abs(u.x - enemy.x) + abs(u.y - enemy.y)
      if d < closest_dist then
        closest = u
        closest_dist = d
      end
    end
  end

  if not closest then
    self:process_next_enemy()
    return
  end

  local best_x, best_y = enemy.x, enemy.y
  local best_dist = closest_dist

  for dy = -enemy.move, enemy.move do
    for dx = -enemy.move, enemy.move do
      if abs(dx) + abs(dy) <= enemy.move then
        local nx, ny = enemy.x + dx, enemy.y + dy
        if nx >= 0 and nx < self.grid_w and ny >= 0 and ny < self.grid_h then
          if not self:unit_at(nx, ny) then
            local d = abs(closest.x - nx) + abs(closest.y - ny)
            if d < best_dist then
              best_dist = d
              best_x, best_y = nx, ny
            end
          end
        end
      end
    end
  end

  enemy.x, enemy.y = best_x, best_y
  tween:new(enemy, {tx = enemy.x, ty = enemy.y}, 15, {
    ease = tween.ease.out_quad,
    on_complete = function()
      if best_dist <= enemy.range then
        self:do_attack(enemy, closest, function()
          self:process_next_enemy()
        end)
      else
        self:process_next_enemy()
      end
    end
  })
end

function game:next_floor()
  self.floor += 1
  self:msg("floor " .. self.floor .. "!")

  for u in all(self.units) do
    if u.team == "player" then
      u.hp = min(u.hp + 5, u.max_hp)
    end
  end

  tween:new({t = 0}, {t = 1}, 60, {
    on_complete = function()
      for i = #self.units, 1, -1 do
        if self.units[i].team == "enemy" then
          deli(self.units, i)
        end
      end

      self:generate_floor()
      self:spawn_enemies()
      self.cam_rot = 0
      self.cam_rot_tween = 0
      self.rotating = false
      self.cursor.x = self.spawn_x
      self.cursor.y = self.spawn_y
      self:center_camera(self.spawn_x, self.spawn_y, true)
      self:start_player_phase()
    end
  })
end

function game:game_over()
  self:msg("game over - floor " .. self.floor)
  self.phase = "gameover"
  input:bind({
    [5] = function()
      self.floor = 1
      self.units = {}
      self:init()
    end
  })
end

function game:center_camera(x, y, instant)
  local target = self:calc_camera_pos(x, y, self.cam_rot_tween)

  if instant then
    self.cam_x = target.x
    self.cam_y = target.y
    self.cam_tween_target = {x = target.x, y = target.y}
  else
    tween:cancel_all(self.cam_tween_target or {})
    self.cam_tween_target = {x = self.cam_x, y = self.cam_y}
    tween:new(self.cam_tween_target, {x = target.x, y = target.y}, 10, {
      ease = tween.ease.out_quad
    })
  end
end

function game:update_camera()
  if self.cam_tween_target then
    self.cam_x = self.cam_tween_target.x
    self.cam_y = self.cam_tween_target.y
  end
end

function game:msg(text)
  self.message = text
  self.msg_timer = 45
end

function game:iso_pos(x, y, h)
  h = h or 0
  local z = self:get_zoom_scale()

  local rot = self.cam_rot_tween
  local cx, cy = self.grid_w / 2, self.grid_h / 2

  local rx, ry = x - cx, y - cy
  local angle = rot * 0.25
  local cos_a, sin_a = cos(angle), sin(angle)
  local nx = rx * cos_a - ry * sin_a
  local ny = rx * sin_a + ry * cos_a
  rx, ry = nx + cx, ny + cy

  local sx = (rx - ry) * (self.tile_w / 2) * z + 64 + self.cam_x
  local sy = (rx + ry) * (self.tile_h / 2) * z + 32 + self.cam_y - h * 4 * z
  return sx, sy
end

function game:update()
  if self.msg_timer > 0 then
    self.msg_timer -= 1
  end
  self:update_camera()
end

function game:get_depth(x, y)
  local rot = self.cam_rot_tween
  local cx, cy = self.grid_w / 2, self.grid_h / 2

  local rx, ry = x - cx, y - cy
  local angle = rot * 0.25
  local cos_a, sin_a = cos(angle), sin(angle)
  local nx = rx * cos_a - ry * sin_a + cx
  local ny = rx * sin_a + ry * cos_a + cy

  return nx + ny
end

function game:get_tile_depth(x, y)
  local base_depth = self:get_depth(x, y)
  local h = 0
  if x >= 0 and x < self.grid_w and y >= 0 and y < self.grid_h then
    h = self.tiles[y][x].height
  end
  return base_depth + h * 0.5
end

function game:draw()
  cls(0)

  local draw_list = {}

  -- add tiles
  for y = 0, self.grid_h - 1 do
    for x = 0, self.grid_w - 1 do
      local depth = self:get_tile_depth(x, y)
      add(draw_list, {type = "tile", x = x, y = y, depth = depth})
    end
  end

  -- add units
  for u in all(self.units) do
    if u.x >= 0 and u.y >= 0 then
      local ux, uy = flr(u.tx + 0.5), flr(u.ty + 0.5)
      local depth = self:get_tile_depth(ux, uy)
      add(draw_list, {type = "unit", unit = u, depth = depth + 0.01})
    end
  end

  -- cursor occlusion logic - per-segment hiding
  local cx, cy = self.cursor.x, self.cursor.y

  -- safety check - make sure cursor is in valid bounds and tile exists
  if not self.tiles[cy] or not self.tiles[cy][cx] then
    -- skip occlusion, just draw all segments
    local cursor_segments = {}
    local segments = {"top_left", "top_right", "right_top", "right_bottom",
                      "bottom_right", "bottom_left", "left_bottom", "left_top"}
    for _, seg in pairs(segments) do
      add(cursor_segments, {segment = seg, hide = false})
    end

    -- sort and draw
    for i = 1, #draw_list - 1 do
      for j = i + 1, #draw_list do
        if draw_list[j].depth < draw_list[i].depth then
          draw_list[i], draw_list[j] = draw_list[j], draw_list[i]
        end
      end
    end

    for item in all(draw_list) do
      if item.type == "tile" then
        self:draw_tile(item.x, item.y)
      elseif item.type == "unit" then
        self:draw_unit(item.unit)
      end
    end

    for item in all(cursor_segments) do
      if not item.hide then
        self:draw_cursor_segment(item.segment)
      end
    end

    self:draw_ui()
    if self.ground_menu then self.ground_menu:draw() end
    if self.options_menu then self.options_menu:draw() end
    if self.action_menu then self.action_menu:draw() end
    if self.deploy_menu then self.deploy_menu:draw() end
    return
  end

  local cur_h = self.tiles[cy][cx].height
  local cur_depth = self:get_depth(cx, cy)

  -- check if a tile at dx,dy from cursor should occlude cursor segments
  -- min_height_diff: how much taller the tile needs to be to occlude
  local function should_occlude(dx, dy, min_height_diff)
    min_height_diff = min_height_diff or 1
    local ax, ay = cx + dx, cy + dy
    if ax < 0 or ax >= self.grid_w or ay < 0 or ay >= self.grid_h then
      return false
    end
    local adj_h = self.tiles[ay][ax].height

    -- must be in front of camera (higher depth = closer)
    local adj_depth = self:get_depth(ax, ay)
    if adj_depth <= cur_depth then return false end

    -- must be tall enough relative to cursor tile
    if adj_h - cur_h < min_height_diff then return false end

    return true
  end

  -- check tiles in front directions
  -- side corners (right/left) only check immediately adjacent tiles
  -- bottom corner: adjacent tiles need height +1, tiles 2 away need height +2
  local rot = flr(self.cam_rot_tween + 0.5) % 4

  local occlude_right, occlude_left, occlude_bottom

  if rot == 0 then
    -- +x is screen-right, +y is screen-left, toward camera is +x/+y
    occlude_right = should_occlude(1, 0)
    occlude_left = should_occlude(0, 1)
    occlude_bottom = should_occlude(1, 0) or should_occlude(0, 1) or
                     should_occlude(1, 1) or should_occlude(2, 0, 2) or
                     should_occlude(0, 2, 2)
  elseif rot == 1 then
    occlude_right = should_occlude(0, 1)
    occlude_left = should_occlude(-1, 0)
    occlude_bottom = should_occlude(0, 1) or should_occlude(-1, 0) or
                     should_occlude(-1, 1) or should_occlude(0, 2, 2) or
                     should_occlude(-2, 0, 2)
  elseif rot == 2 then
    occlude_right = should_occlude(-1, 0)
    occlude_left = should_occlude(0, -1)
    occlude_bottom = should_occlude(-1, 0) or should_occlude(0, -1) or
                     should_occlude(-1, -1) or should_occlude(-2, 0, 2) or
                     should_occlude(0, -2, 2)
  else -- rot == 3
    occlude_right = should_occlude(0, -1)
    occlude_left = should_occlude(1, 0)
    occlude_bottom = should_occlude(0, -1) or should_occlude(1, 0) or
                     should_occlude(1, -1) or should_occlude(0, -2, 2) or
                     should_occlude(2, 0, 2)
  end

  local hide_top_corner = false  -- away from camera, never occluded
  local hide_right_corner = occlude_right
  local hide_bottom_corner = occlude_bottom
  local hide_left_corner = occlude_left

  -- check for unit on cursor tile (top segments hide behind unit)
  local unit_on_cursor = self:unit_at(cx, cy)

  -- add cursor segments to a separate list - drawn after everything else
  local cursor_segments = {}

  -- top corner segments (both hide if top corner is occluded, or if unit is on tile)
  add(cursor_segments, {segment = "top_left", hide = hide_top_corner or unit_on_cursor})
  add(cursor_segments, {segment = "top_right", hide = hide_top_corner or unit_on_cursor})

  -- right corner segments
  add(cursor_segments, {segment = "right_top", hide = hide_right_corner})
  add(cursor_segments, {segment = "right_bottom", hide = hide_right_corner})

  -- bottom corner segments
  add(cursor_segments, {segment = "bottom_right", hide = hide_bottom_corner})
  add(cursor_segments, {segment = "bottom_left", hide = hide_bottom_corner})

  -- left corner segments
  add(cursor_segments, {segment = "left_bottom", hide = hide_left_corner})
  add(cursor_segments, {segment = "left_top", hide = hide_left_corner})

  -- sort by depth
  for i = 1, #draw_list - 1 do
    for j = i + 1, #draw_list do
      if draw_list[j].depth < draw_list[i].depth then
        draw_list[i], draw_list[j] = draw_list[j], draw_list[i]
      end
    end
  end

  -- draw in sorted order
  for item in all(draw_list) do
    if item.type == "tile" then
      self:draw_tile(item.x, item.y)
    elseif item.type == "unit" then
      self:draw_unit(item.unit)
    end
  end

  -- draw cursor segments last (after all tiles/units) to prevent clipping
  for item in all(cursor_segments) do
    if not item.hide then
      self:draw_cursor_segment(item.segment)
    end
  end

  self:draw_ui()

  if self.options_menu then self.options_menu:draw() end
  if self.action_menu then self.action_menu:draw() end
  if self.deploy_menu then self.deploy_menu:draw() end
end

function game:get_zoom_scale()
  local zt = self.zoom_tween
  if zt <= 1 then
    return self.zoom_levels[1]
  elseif zt <= 2 then
    return self.zoom_levels[1] + (zt - 1) * (self.zoom_levels[2] - self.zoom_levels[1])
  else
    return self.zoom_levels[2] + (zt - 2) * (self.zoom_levels[3] - self.zoom_levels[2])
  end
end

function game:draw_tile(x, y)
  local tile = self.tiles[y][x]
  local h = tile.height
  local sx, sy = self:iso_pos(x, y, h)
  local z = self:get_zoom_scale()

  local col = tile.col

  local is_move = self:tile_in_list(x, y, self.move_tiles)
  local is_attack = self:tile_in_list(x, y, self.attack_tiles)
  if is_move then
    col = 12  -- blue for move
  elseif is_attack then
    col = 8   -- red for attack
  end

  local hw, hh = (self.tile_w / 2) * z, (self.tile_h / 2) * z
  local hpx = h * 4 * z

  if h > 0 then
    local lc = col - 1
    if lc < 0 then lc = 0 end
    for i = 0, hpx do
      line(sx - hw, sy + i, sx, sy + hh + i, lc)
    end
    local rc = col - 2
    if rc < 0 then rc = 0 end
    for i = 0, hpx do
      line(sx, sy + hh + i, sx + hw, sy + i, rc)
    end
  end

  for i = 0, hh do
    local w = (hw * (hh - i)) / hh
    line(sx - w, sy - i, sx + w, sy - i, col)
    line(sx - w, sy + i, sx + w, sy + i, col)
  end

  -- pulsing inner diamond for special tiles
  if not is_move and not is_attack then
    if tile.type == "spawn" then
      local pulse = 0.5 + 0.5 * sin(time() * 2)
      local inner_col = pulse > 0.5 and 12 or 1
      local iw, ih = hw * 0.5, hh * 0.5
      for i = 0, ih do
        local w = (iw * (ih - i)) / ih
        line(sx - w, sy - i, sx + w, sy - i, inner_col)
        line(sx - w, sy + i, sx + w, sy + i, inner_col)
      end
    elseif tile.type == "goal" then
      local pulse = 0.5 + 0.5 * sin(time() * 2)
      local inner_col = pulse > 0.5 and 9 or 8
      local iw, ih = hw * 0.5, hh * 0.5
      for i = 0, ih do
        local w = (iw * (ih - i)) / ih
        line(sx - w, sy - i, sx + w, sy - i, inner_col)
        line(sx - w, sy + i, sx + w, sy + i, inner_col)
      end
    end
  end

  line(sx, sy - hh, sx + hw, sy, 0)
  line(sx + hw, sy, sx, sy + hh, 0)
  line(sx, sy + hh, sx - hw, sy, 0)
  line(sx - hw, sy, sx, sy - hh, 0)

  if h > 0 then
    line(sx - hw, sy, sx - hw, sy + hpx, 0)
    line(sx + hw, sy, sx + hw, sy + hpx, 0)
    line(sx - hw, sy + hpx, sx, sy + hh + hpx, 0)
    line(sx, sy + hh + hpx, sx + hw, sy + hpx, 0)
  end
end

function game:draw_unit(u)
  local h = self.tiles[flr(u.ty + 0.5)] and self.tiles[flr(u.ty + 0.5)][flr(u.tx + 0.5)]
  h = h and h.height or 0
  local sx, sy = self:iso_pos(u.tx, u.ty, h)
  local z = self:get_zoom_scale()

  local col = u.col

  circfill(sx, sy - 4 * z, 3 * z, col)
  circfill(sx, sy - 8 * z, 2 * z, col)
  ovalfill(sx - 2 * z, sy, sx + 2 * z, sy + 1 * z, 0)

  if u.hp < u.max_hp then
    local bw = 8 * z
    local pct = u.hp / u.max_hp
    rectfill(sx - bw/2, sy - 14 * z, sx + bw/2, sy - 12 * z, 0)
    rectfill(sx - bw/2, sy - 14 * z, sx - bw/2 + bw * pct, sy - 12 * z, u.team == "player" and 11 or 8)
  end

  if u.team == "player" and u.acted then
    print("z", sx - 2, sy - 16 * z, 5)
  end
end

function game:draw_cursor_segment(segment)
  local h = self.tiles[self.cursor.y] and self.tiles[self.cursor.y][self.cursor.x]
  h = h and h.height or 0
  local sx, sy = self:iso_pos(self.cursor.x, self.cursor.y, h)
  local z = self:get_zoom_scale()

  local t = time() * 3
  local expand = 1 + sin(t) * 0.15

  local hw, hh = (self.tile_w / 2) * z * expand, (self.tile_h / 2) * z * expand
  local col = 10  -- yellow cursor
  local outline = 0
  local len = 2 * z

  local function oline(x1, y1, x2, y2)
    line(x1-1, y1, x2-1, y2, outline)
    line(x1+1, y1, x2+1, y2, outline)
    line(x1, y1-1, x2, y2-1, outline)
    line(x1, y1+1, x2, y2+1, outline)
    line(x1, y1, x2, y2, col)
  end

  if segment == "top_left" then
    local tx, ty = sx, sy - hh
    oline(tx - len, ty + len * 0.5, tx, ty)
  elseif segment == "top_right" then
    local tx, ty = sx, sy - hh
    oline(tx, ty, tx + len, ty + len * 0.5)
  elseif segment == "right_top" then
    local rx, ry = sx + hw, sy
    oline(rx - len, ry - len * 0.5, rx, ry)
  elseif segment == "right_bottom" then
    local rx, ry = sx + hw, sy
    oline(rx, ry, rx - len, ry + len * 0.5)
  elseif segment == "bottom_right" then
    local bx, by = sx, sy + hh
    oline(bx - len, by - len * 0.5, bx, by)
  elseif segment == "bottom_left" then
    local bx, by = sx, sy + hh
    oline(bx, by, bx + len, by - len * 0.5)
  elseif segment == "left_bottom" then
    local lx, ly = sx - hw, sy
    oline(lx + len, ly - len * 0.5, lx, ly)
  elseif segment == "left_top" then
    local lx, ly = sx - hw, sy
    oline(lx, ly, lx + len, ly + len * 0.5)
  end
end

function game:draw_ui()
  rectfill(0, 0, 127, 8, 0)
  print("floor " .. self.floor, 2, 2, 13)

  local u = self:unit_at(self.cursor.x, self.cursor.y)
  if u then
    rectfill(0, 112, 60, 127, 0)
    rect(0, 112, 60, 127, 13)
    print(u.name, 2, 114, u.col)
    print("hp:" .. u.hp .. "/" .. u.max_hp, 2, 120, 7)
  end

  if self.selected then
    local su = self.selected
    rectfill(68, 112, 127, 127, 0)
    rect(68, 112, 127, 127, 13)
    print(su.name, 70, 114, su.col)
    print("atk:" .. su.atk .. " def:" .. su.def, 70, 120, 7)
  end

  local hint = ""
  if self.phase == "select" then
    local cu = self:unit_at(self.cursor.x, self.cursor.y)
    if cu and cu.team == "player" and cu.moved and not cu.acted then
      hint = "❎menu 🅾️undo"
    else
      hint = "❎sel/menu"
    end
  elseif self.phase == "move" then
    hint = "❎move 🅾️back"
  elseif self.phase == "action" then
    hint = "❎sel 🅾️back"
  elseif self.phase == "target" then
    hint = "❎target 🅾️back"
  elseif self.phase == "gameover" then
    hint = "❎retry"
  end
  print(hint, 64 - #hint * 2, 2, 6)

  if self.msg_timer > 0 then
    local w = #self.message * 4
    rectfill(62 - w/2, 58, 66 + w/2, 68, 0)
    print(self.message, 64 - w / 2, 60, 10)
  end
end
