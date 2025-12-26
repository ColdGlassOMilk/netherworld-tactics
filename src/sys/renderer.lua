-- renderer system

renderer = {}

-- helper: draw outlined line
local function oline(x1, y1, x2, y2, col)
  line(x1-1, y1, x2-1, y2, 0)
  line(x1+1, y1, x2+1, y2, 0)
  line(x1, y1-1, x2, y2-1, 0)
  line(x1, y1+1, x2, y2+1, 0)
  line(x1, y1, x2, y2, col)
end

-- helper: draw filled diamond
local function diamond(sx, sy, hw, hh, col)
  for i = 0, hh do
    local w = hw * (hh - i) / hh
    line(sx - w, sy - i, sx + w, sy - i, col)
    line(sx - w, sy + i, sx + w, sy + i, col)
  end
end

function renderer:draw_all()
  local draw_list = {}

  -- add tiles and units to draw list
  for y = 0, grid.h - 1 do
    for x = 0, grid.w - 1 do
      add(draw_list, {t = "tile", x = x, y = y, d = grid:get_tile_depth(x, y)})
    end
  end

  for u in all(units.list) do
    if u.x >= 0 then
      local ux, uy = flr(u.tx + 0.5), flr(u.ty + 0.5)
      add(draw_list, {t = "unit", u = u, d = grid:get_tile_depth(ux, uy) + 0.01})
    end
  end

  -- sort by depth
  for i = 1, #draw_list - 1 do
    for j = i + 1, #draw_list do
      if draw_list[j].d < draw_list[i].d then
        draw_list[i], draw_list[j] = draw_list[j], draw_list[i]
      end
    end
  end

  -- draw sorted
  for item in all(draw_list) do
    if item.t == "tile" then
      self:draw_tile(item.x, item.y)
    else
      self:draw_unit(item.u)
    end
  end

  -- cursor
  self:draw_cursor()

  -- markers when O held long enough
  if bindings.show_markers then self:draw_markers() end
end

function renderer:draw_tile(x, y)
  local tile = grid.tiles[y][x]
  local h = tile.height
  local sx, sy = camera:iso_pos(x, y, h)
  local z = camera:get_zoom_scale()
  local hw, hh = (grid.tile_w / 2) * z, (grid.tile_h / 2) * z
  local hpx = h * 4 * z

  -- determine color
  local col = tile.col
  local is_move = grid:tile_in_list(x, y, game.move_tiles or {})
  local is_attack = grid:tile_in_list(x, y, game.attack_tiles or {})
  if is_move then col = 12
  elseif is_attack then col = 8 end

  -- sides
  if h > 0 then
    for i = 0, hpx do
      line(sx - hw, sy + i, sx, sy + hh + i, max(0, col - 1))
      line(sx, sy + hh + i, sx + hw, sy + i, max(0, col - 2))
    end
  end

  -- top face
  diamond(sx, sy, hw, hh, col)

  -- pulsing inner for special tiles
  if not is_move and not is_attack and (tile.type == "spawn" or tile.type == "goal") then
    local pulse = sin(time() * 2) > 0
    local c1, c2 = 12, 1
    if tile.type == "goal" then c1, c2 = 9, 8 end
    diamond(sx, sy, hw * 0.5, hh * 0.5, pulse and c1 or c2)
  end

  -- outline
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

function renderer:draw_unit(u)
  local h = grid:get_height(flr(u.tx + 0.5), flr(u.ty + 0.5))
  local sx, sy = camera:iso_pos(u.tx, u.ty, h)
  local z = camera:get_zoom_scale()

  -- body outline
  circfill(sx, sy - 4 * z, 3 * z + 1, 0)
  -- head outline
  circfill(sx, sy - 8 * z, 2 * z + 1, 0)
  -- body
  circfill(sx, sy - 4 * z, 3 * z, u.col)
  -- head
  circfill(sx, sy - 8 * z, 2 * z, u.col)
  -- shadow
  ovalfill(sx - 2 * z, sy, sx + 2 * z, sy + 1 * z, 0)

  if u.hp < u.max_hp then
    local bw, by = 8 * z, sy - 14 * z
    rectfill(sx - bw/2, by, sx + bw/2, by + 2, 0)
    rectfill(sx - bw/2, by, sx - bw/2 + bw * u.hp / u.max_hp, by + 2, u.team == "player" and 11 or 8)
  end

  if u.team == "player" and u.acted then
    print("z", sx - 2, sy - 16 * z, 5)
  end
end

function renderer:draw_cursor()
  local cx, cy = cursor.x, cursor.y
  if not grid:get_tile(cx, cy) then return end

  local h = grid:get_height(cx, cy)
  local sx, sy = camera:iso_pos(cx, cy, h)
  local z = camera:get_zoom_scale()
  local expand = 1 + sin(time() * 3) * 0.15
  local hw, hh = (grid.tile_w / 2) * z * expand, (grid.tile_h / 2) * z * expand
  local len = 2 * z

  -- occlusion check - only hide if adjacent tile is taller AND in front
  local cur_depth = camera:get_depth(cx, cy)
  local function occluded(dx, dy)
    local ax, ay = cx + dx, cy + dy
    if not grid:is_valid(ax, ay) then return false end
    local adj_h = grid:get_height(ax, ay)
    local adj_d = camera:get_depth(ax, ay)
    -- must be in front (higher depth) and taller
    return adj_d > cur_depth and adj_h > h
  end

  local rot = flr(camera.rot_tween + 0.5) % 4
  local dirs = {{1,0,0,1}, {0,1,-1,0}, {-1,0,0,-1}, {0,-1,1,0}}
  local d = dirs[rot + 1]

  -- right/left only check immediate neighbors
  local occ_r = occluded(d[1], d[2])
  local occ_l = occluded(d[3], d[4])
  -- bottom only hides if the diagonal front tile is taller
  local occ_b = occluded(d[1]+d[3], d[2]+d[4])
  local occ_t = units:at(cx, cy)

  -- segment data: corner x/y offsets, line direction
  local segs = {
    {0, -hh, -len, len*0.5, occ_t},      -- top_left
    {0, -hh, len, len*0.5, occ_t},       -- top_right
    {hw, 0, -len, -len*0.5, occ_r},      -- right_top
    {hw, 0, -len, len*0.5, occ_r},       -- right_bottom
    {0, hh, -len, -len*0.5, occ_b},      -- bottom_right
    {0, hh, len, -len*0.5, occ_b},       -- bottom_left
    {-hw, 0, len, -len*0.5, occ_l},      -- left_bottom
    {-hw, 0, len, len*0.5, occ_l}        -- left_top
  }

  for s in all(segs) do
    if not s[5] then
      local px, py = sx + s[1], sy + s[2]
      oline(px, py, px + s[3], py + s[4], 10)
    end
  end
end

function renderer:draw_markers()
  local markers = {
    {x = grid.spawn_x, y = grid.spawn_y, col = 12},
    {x = grid.goal_x, y = grid.goal_y, col = 9}
  }
  -- crystal outline offsets: {width, y_offsets...}
  local outline = {{0,-7}, {1,-6}, {2,-5,-4}, {3,-3,-2,-1}, {4,0,1}, {3,2,3,4}, {2,5,6}, {1,7}, {0,8}}

  for m in all(markers) do
    local h = grid:get_height(m.x, m.y)
    local sx, sy = camera:iso_pos(m.x, m.y, h)
    local cy = sy - 18 + sin(time() * 2) * 2

    -- outline
    for o in all(outline) do
      local w = o[1]
      for i = 2, #o do
        pset(sx - w, cy + o[i], 0)
        if w > 0 then pset(sx + w, cy + o[i], 0) end
      end
    end

    -- fill
    pset(sx, cy - 6, m.col)
    rectfill(sx - 1, cy - 5, sx + 1, cy - 4, m.col)
    rectfill(sx - 2, cy - 3, sx + 2, cy - 1, m.col)
    rectfill(sx - 3, cy, sx + 3, cy + 1, m.col)
    rectfill(sx - 2, cy + 2, sx + 2, cy + 4, m.col)
    rectfill(sx - 1, cy + 5, sx + 1, cy + 6, m.col)
    pset(sx, cy + 7, m.col)
  end
end
