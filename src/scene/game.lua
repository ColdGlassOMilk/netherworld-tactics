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
  sprites:update_all()
end

function game:draw()
  -- secret palette swaps for netherworld vibe
  -- PICO-8 secret palette (128-143):
  -- 128: dark brown, 129: darker brown, 130: dark gray-green
  -- 131: dark blue, 132: light indigo, 133: dark gray
  -- 134: light peach, 135: tan, 136: dark red/maroon
  -- 137: dark orange, 138: dark yellow, 139: dark green
  -- 140: dark cyan, 141: medium blue, 142: light purple
  -- 143: pink-gray

  -- deep netherworld purples
  pal(1, 131, 1)   -- dark blue -> darker blue
  pal(2, 129, 1)   -- dark purple -> deep brown-purple
  pal(5, 133, 1)   -- dark gray -> darker gray

  -- ethereal highlights
  pal(13, 132, 1)  -- lavender -> soft indigo
  pal(14, 143, 1)  -- pink -> muted pink
  pal(15, 134, 1)  -- peach -> light peach

  -- fiery accents
  pal(8, 136, 1)   -- red -> deep crimson
  pal(9, 137, 1)   -- orange -> burnt orange
  pal(10, 138, 1)  -- yellow -> gold

  -- ghostly enemies
  pal(11, 139, 1)  -- green -> murky green

  -- cyan move tiles stay vibrant
  pal(12, 140, 1)  -- blue -> teal

  cls(0)
  renderer:draw_all()
  ui:draw()

  if self.action_menu then self.action_menu:draw() end
  if self.deploy_menu then self.deploy_menu:draw() end
  if self.options_menu then self.options_menu:draw() end

  -- reset palette
  pal()
end
