-- units system

units = {
  -- list = {}
}

function units:init()
  self.list = {}

  -- create player units
  -- vex: melee warrior - fiery orange/red
  local vex = {
    name = "vex",
    team = "player",
    hp = 20, max_hp = 20,
    atk = 5, def = 2, spd = 10,
    move = 5, range = 1,
    x = -1, y = -1,
    tx = -1, ty = -1,
    deployed = false,
    acted = false,
    moved = false
  }
  sprites:init_unit(vex)
  add(self.list, vex)

  -- nyx: ranged mage - mystical pink/magenta
  local nyx = {
    name = "nyx",
    team = "player",
    hp = 12, max_hp = 12,
    atk = 8, def = 0, spd = 8,
    move = 4, range = 2,
    x = -1, y = -1,
    tx = -1, ty = -1,
    deployed = false,
    acted = false,
    moved = false
  }
  sprites:init_unit(nyx)
  add(self.list, nyx)
end

function units:at(x, y)
  for u in all(self.list) do
    if u.x == x and u.y == y then return u end
  end
  return nil
end

function units:spawn(x, y, data)
  local unit = {
    x = x, y = y,
    tx = x, ty = y,
    acted = false,
    moved = false
  }
  for k, v in pairs(data) do
    unit[k] = v
  end
  sprites:init_unit(unit)
  add(self.list, unit)
  return unit
end

function units:spawn_enemies(floor)
  local count = 2 + flr(floor / 2)

  for i = 1, count do
    local x, y
    repeat
      x = flr(rnd(grid.w))
      y = flr(rnd(grid.h))
    until not self:at(x, y) and
          not (x == grid.spawn_x and y == grid.spawn_y) and
          not (x == grid.goal_x and y == grid.goal_y)

    self:spawn(x, y, {
      name = "imp",
      team = "enemy",
      hp = 5 + floor * 2,
      max_hp = 5 + floor * 2,
      atk = 2 + flr(floor / 2),
      def = 0, spd = 6,
      move = 2, range = 1
    })
  end
end

function units:remove(u)
  del(self.list, u)
end

function units:get_players()
  local result = {}
  for u in all(self.list) do
    if u.team == "player" then add(result, u) end
  end
  return result
end

function units:get_enemies()
  local result = {}
  for u in all(self.list) do
    if u.team == "enemy" then add(result, u) end
  end
  return result
end

function units:count_team(team)
  local count = 0
  for u in all(self.list) do
    if u.team == team then count += 1 end
  end
  return count
end

function units:check_dead()
  for u in all(self.list) do
    if u.hp <= 0 then
      del(self.list, u)
      sfx(3)
    end
  end

  local players = self:count_team("player")
  local enemies = self:count_team("enemy")

  if enemies == 0 then
    game:next_floor()
    return true
  elseif players == 0 then
    game:game_over()
    return true
  end
  return false
end
