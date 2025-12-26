-- game scene (coordinator)

game = {
  floor = 1,
  phase = "select",
  message = "",
  msg_timer = 0,
  action_queue = {},
  enemy_queue = {}
}

function game:init()
  self.floor = 1
  self.phase = "select"
  self.action_queue = {}

  -- initialize subsystems
  camera:init()
  grid:init()
  units:init()
  cursor:init()

  -- generate first floor
  grid:generate()
  units:spawn_enemies(self.floor)

  -- position cursor at spawn
  cursor.x = grid.spawn_x
  cursor.y = grid.spawn_y
  camera:center(cursor.x, cursor.y, true)

  self:start_player_phase()
end

function game:start_player_phase()
  self.phase = "select"
  self.selected = nil
  self.move_tiles = {}
  self.attack_tiles = {}
  self.action_queue = {}

  -- reset menus
  self.options_menu = nil
  self.action_menu = nil
  self.deploy_menu = nil

  -- reset player units
  for u in all(units.list) do
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
  bindings:bind_select()
end

function game:start_enemy_phase()
  self.phase = "enemy"
  self:msg("enemy phase")

  self.enemy_queue = {}
  for u in all(units.list) do
    if u.team == "enemy" then
      add(self.enemy_queue, u)
    end
  end

  self:process_next_enemy()
end

function game:process_next_enemy()
  if #self.enemy_queue == 0 then
    self:start_player_phase()
    return
  end

  local enemy = deli(self.enemy_queue, 1)
  ai:process_enemy(enemy, function()
    self:process_next_enemy()
  end)
end

function game:execute_turn()
  if #self.action_queue == 0 then
    self.phase = "select"
    bindings:bind_select()
    return
  end

  -- only mark units that have queued actions as acted
  for action in all(self.action_queue) do
    if action.attacker and action.attacker.team == "player" then
      action.attacker.acted = true
    end
  end

  self.phase = "execute"
  self.end_turn_after_execute = false
  input:clear()
  self:process_next_action()
end

function game:execute_and_end_turn()
  -- mark all moved units as acted when ending turn
  for u in all(units.list) do
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
      bindings:bind_select()
    end
    return
  end

  local action = deli(self.action_queue, 1)
  if action.type == "attack" then
    combat:do_attack(action.attacker, action.target, function()
      self:process_next_action()
    end)
  end
end

function game:next_floor()
  self.floor += 1
  self:msg("floor " .. self.floor .. "!")

  -- heal players
  for u in all(units.list) do
    if u.team == "player" then
      u.hp = min(u.hp + 5, u.max_hp)
    end
  end

  tween:new({t = 0}, {t = 1}, 60, {
    on_complete = function()
      -- remove enemies
      for i = #units.list, 1, -1 do
        if units.list[i].team == "enemy" then
          deli(units.list, i)
        end
      end

      -- regenerate
      grid:generate()
      units:spawn_enemies(self.floor)

      -- reset camera
      camera:reset()
      cursor.x = grid.spawn_x
      cursor.y = grid.spawn_y
      camera:center(cursor.x, cursor.y, true)

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
      units.list = {}
      self:init()
    end
  })
end

function game:msg(text)
  self.message = text
  self.msg_timer = 45
end

function game:update()
  if self.msg_timer > 0 then
    self.msg_timer -= 1
  end
  camera:update()
  bindings:update()
end

function game:draw()
  cls(0)
  renderer:draw_all()
  ui:draw()

  if self.action_menu then self.action_menu:draw() end
  if self.deploy_menu then self.deploy_menu:draw() end
  if self.options_menu then self.options_menu:draw() end
end
