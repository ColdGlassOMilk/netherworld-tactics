-- cursor system

cursor = {
  -- x = 0,
  -- y = 0
}

function cursor:init()
  self.x = 0
  self.y = 0
end

function cursor:move(dx, dy)
  local nx, ny = self.x, self.y
  local rot = camera.rot

  -- rotate input based on camera
  for i = 1, rot do
    dx, dy = -dy, dx
  end

  local gx, gy = 0, 0
  if camera.cam_left then
    gx, gy = dx, dy
  else
    gx, gy = dy, -dx
  end

  nx = mid(0, self.x + gx, grid.w - 1)
  ny = mid(0, self.y + gy, grid.h - 1)

  -- lock cursor to move tiles during move phase
  -- but allow navigating through units if the tile would otherwise be reachable
  if game.fsm.current == "move" then
    local in_move = grid:tile_in_list(nx, ny, game.move_tiles)
    local has_unit = units:at(nx, ny)
    if not in_move then
      -- if there's a unit, check if tile is within movement range
      if has_unit and game.selected then
        local dist = abs(nx - game.selected.x) + abs(ny - game.selected.y)
        if dist > game.selected.move then
          return
        end
      else
        return
      end
    end
  end

  self.x, self.y = nx, ny
  camera:center(self.x, self.y)
  sfx(0)
end

function cursor:get_tile()
  return grid:get_tile(self.x, self.y)
end

function cursor:get_unit()
  return units:at(self.x, self.y)
end
