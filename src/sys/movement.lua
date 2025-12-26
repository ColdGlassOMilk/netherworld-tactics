-- movement system

movement = {}

function movement:calc_tiles(unit)
  local tiles = {}
  add(tiles, {x = unit.x, y = unit.y})

  local visited = {}
  local queue = {{x = unit.x, y = unit.y, cost = 0}}

  -- 4 cardinal directions only
  local dirs = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}

  while #queue > 0 do
    -- find lowest cost
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

      -- check for unit at current position
      local other = units:at(cur.x, cur.y)
      local is_enemy = other and other.team != unit.team

      -- can't move through enemies
      if is_enemy then
        -- don't add to tiles or expand from here
      else
        -- add as valid destination if empty
        if not other and (cur.x != unit.x or cur.y != unit.y) then
          add(tiles, {x = cur.x, y = cur.y})
        end

        -- expand to neighbors (can pass through allies)
        for _, dir in pairs(dirs) do
          local nx, ny = cur.x + dir[1], cur.y + dir[2]
          if grid:is_valid(nx, ny) then
            local nkey = nx .. "," .. ny
            if not visited[nkey] then
              local cur_h = grid:get_height(cur.x, cur.y)
              local next_h = grid:get_height(nx, ny)
              local climb = next_h - cur_h

              -- cost = 1 base + climb cost (only if going up)
              local move_cost = 1
              if climb > 0 then
                move_cost = move_cost + climb
              end
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

  return tiles
end

function movement:calc_attack_tiles(unit, from_x, from_y)
  local tiles = {}

  for dy = -unit.range, unit.range do
    for dx = -unit.range, unit.range do
      if abs(dx) + abs(dy) <= unit.range and (dx != 0 or dy != 0) then
        local tx, ty = from_x + dx, from_y + dy
        if grid:is_valid(tx, ty) then
          add(tiles, {x = tx, y = ty})
        end
      end
    end
  end

  return tiles
end

function movement:get_valid_targets(attack_tiles)
  local targets = {}
  for t in all(attack_tiles) do
    local unit = units:at(t.x, t.y)
    if unit and unit.team == "enemy" then
      add(targets, {x = t.x, y = t.y, unit = unit})
    end
  end
  return targets
end
