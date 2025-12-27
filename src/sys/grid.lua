-- grid system

grid = {
  w = 10,
  h = 10,
  tile_w = 16,
  tile_h = 8,
  -- tiles = {},
  spawn_x = 0,
  spawn_y = 0,
  goal_x = 0,
  goal_y = 0
}

function grid:init()
  self.tiles = {}
end

function grid:generate()
  self.tiles = {}

  -- generate terrain with varying heights
  -- netherworld palette: consistent colors per height
  for y = 0, self.h - 1 do
    self.tiles[y] = {}
    for x = 0, self.w - 1 do
      local h = 0
      local r = rnd()
      if r > 0.4 then h = 1 end
      if r > 0.75 then h = 2 end

      -- consistent color per height level
      local col
      if h == 0 then
        col = 1   -- dark blue (lowest)
      elseif h == 1 then
        col = 2   -- dark purple (mid)
      else
        col = 13  -- lavender (highest)
      end

      self.tiles[y][x] = {
        height = h,
        col = col,
        type = "normal"
      }
    end
  end

  -- place spawn point - glowing blue
  self.spawn_x = flr(rnd(self.w))
  self.spawn_y = flr(rnd(self.h))
  self.tiles[self.spawn_y][self.spawn_x].height = 0
  self.tiles[self.spawn_y][self.spawn_x].col = 1
  self.tiles[self.spawn_y][self.spawn_x].type = "spawn"

  -- place goal (away from spawn) - glowing red/orange
  local gx, gy
  repeat
    gx = flr(rnd(self.w))
    gy = flr(rnd(self.h))
  until (gx != self.spawn_x or gy != self.spawn_y) and
        (abs(gx - self.spawn_x) + abs(gy - self.spawn_y) >= 4)

  self.tiles[gy][gx].height = 0
  self.tiles[gy][gx].col = 2
  self.tiles[gy][gx].type = "goal"
  self.goal_x, self.goal_y = gx, gy

  -- reset player deployments
  for u in all(units.list) do
    if u.team == "player" then
      u.deployed = false
      u.x, u.y = -1, -1
      u.tx, u.ty = -1, -1
    end
  end
end

function grid:get_tile(x, y)
  if x < 0 or x >= self.w or y < 0 or y >= self.h then
    return nil
  end
  return self.tiles[y] and self.tiles[y][x]
end

function grid:get_height(x, y)
  local tile = self:get_tile(x, y)
  return tile and tile.height or 0
end

function grid:get_tile_depth(x, y)
  local base_depth = camera:get_depth(x, y)
  local h = self:get_height(x, y)
  return base_depth + h * 0.5
end

function grid:is_valid(x, y)
  return x >= 0 and x < self.w and y >= 0 and y < self.h
end

function grid:tile_in_list(x, y, list)
  for t in all(list) do
    if t.x == x and t.y == y then return true end
  end
  return false
end
