-- camera system

camera = {
  -- x = 0,
  -- y = -20,
  -- rot = 0,
  -- rot_tween = 0,
  -- zoom = 2,
  -- zoom_tween = 2,
  zoom_levels = {1, 2, 3},  -- integer values only for clean pixel scaling
  -- zooming = false,
  -- rotating = false,
  -- tween_target = nil,
  cam_left = false
}

function camera:init()
  self.x = 0
  self.y = -20
  self.rot = 0
  self.rot_tween = 0
  self.zoom = 2
  self.zoom_tween = 2
  self.zooming = false
  self.rotating = false
  self.tween_target = nil
end

function camera:reset()
  self.rot = 0
  self.rot_tween = 0
  self.rotating = false
end

function camera:center(x, y, instant)
  local target = self:calc_pos(x, y, self.rot_tween)

  if instant then
    self.x = target.x
    self.y = target.y
    self.tween_target = {x = target.x, y = target.y}
  else
    tween:cancel_all(self.tween_target or {})
    self.tween_target = {x = self.x, y = self.y}
    tween:new(self.tween_target, {x = target.x, y = target.y}, 10, {
      ease = tween.ease.out_quad
    })
  end
end

function camera:calc_pos(x, y, rot, zoom)
  zoom = zoom or self.zoom
  local z = self.zoom_levels[zoom]
  local cx, cy = grid.w / 2, grid.h / 2

  local rx, ry = x - cx, y - cy
  local angle = rot * 0.25
  local cos_a, sin_a = cos(angle), sin(angle)
  local nx = rx * cos_a - ry * sin_a
  local ny = rx * sin_a + ry * cos_a
  rx, ry = nx + cx, ny + cy

  local sx = (rx - ry) * (grid.tile_w / 2) * z + 64
  local sy = (rx + ry) * (grid.tile_h / 2) * z + 32

  return {x = 64 - sx, y = 64 - sy}
end

function camera:rotate(dir)
  if self.rotating then return end
  self.rotating = true

  local target = (self.rot + dir) % 4
  if target < 0 then target = target + 4 end
  local tween_target = self.rot + dir
  local final_cam = self:calc_pos(cursor.x, cursor.y, tween_target)

  tween:cancel_all(self.tween_target or {})
  self.tween_target = {x = self.x, y = self.y}

  tween:new(self, {rot_tween = tween_target}, 15, {
    ease = tween.ease.out_quad,
    on_complete = function()
      self.rot = target
      self.rot_tween = target
      self.rotating = false
    end
  })

  tween:new(self.tween_target, {x = final_cam.x, y = final_cam.y}, 15, {
    ease = tween.ease.out_quad
  })
  sfx(0)
end

function camera:change_zoom(dir)
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

  local target = self:calc_pos(cursor.x, cursor.y, self.rot_tween, new_zoom)
  tween:cancel_all(self.tween_target or {})
  self.tween_target = {x = self.x, y = self.y}
  tween:new(self.tween_target, {x = target.x, y = target.y}, 15, {
    ease = tween.ease.out_quad
  })
  sfx(0)
end

function camera:update()
  if self.tween_target then
    self.x = self.tween_target.x
    self.y = self.tween_target.y
  end
end

function camera:get_zoom_scale()
  local zt = self.zoom_tween
  if zt <= 1 then
    return self.zoom_levels[1]
  elseif zt <= 2 then
    return self.zoom_levels[1] + (zt - 1) * (self.zoom_levels[2] - self.zoom_levels[1])
  else
    return self.zoom_levels[2] + (zt - 2) * (self.zoom_levels[3] - self.zoom_levels[2])
  end
end

-- convert grid coords to screen coords
function camera:iso_pos(x, y, h)
  h = h or 0
  local z = self:get_zoom_scale()

  local rot = self.rot_tween
  local cx, cy = grid.w / 2, grid.h / 2

  local rx, ry = x - cx, y - cy
  local angle = rot * 0.25
  local cos_a, sin_a = cos(angle), sin(angle)
  local nx = rx * cos_a - ry * sin_a
  local ny = rx * sin_a + ry * cos_a
  rx, ry = nx + cx, ny + cy

  local sx = (rx - ry) * (grid.tile_w / 2) * z + 64 + self.x
  local sy = (rx + ry) * (grid.tile_h / 2) * z + 32 + self.y - h * 4 * z
  return sx, sy
end

function camera:get_depth(x, y)
  local rot = self.rot_tween
  local cx, cy = grid.w / 2, grid.h / 2

  local rx, ry = x - cx, y - cy
  local angle = rot * 0.25
  local cos_a, sin_a = cos(angle), sin(angle)
  local nx = rx * cos_a - ry * sin_a + cx
  local ny = rx * sin_a + ry * cos_a + cy

  return nx + ny
end
