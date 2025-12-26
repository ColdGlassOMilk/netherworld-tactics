-- cursor system

cursor = {
  x = 0,
  y = 0
}

function cursor:init()
  self.x = 0
  self.y = 0
end

function cursor:move(dx, dy)
  local gx, gy = 0, 0
  local rot = camera.rot

  -- rotate input based on camera
  for i = 1, rot do
    dx, dy = -dy, dx
  end

  if camera.cam_left then
    gx, gy = dx, dy
  else
    gx = dy
    gy = -dx
  end

  self.x = mid(0, self.x + gx, grid.w - 1)
  self.y = mid(0, self.y + gy, grid.h - 1)
  camera:center(self.x, self.y)
  sfx(0)
end

function cursor:get_tile()
  return grid:get_tile(self.x, self.y)
end

function cursor:get_unit()
  return units:at(self.x, self.y)
end
