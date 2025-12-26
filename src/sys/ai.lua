-- ai system

ai = {}

function ai:process_enemy(enemy, on_done)
  -- find closest player
  local closest, closest_dist = nil, 999
  for u in all(units.list) do
    if u.team == "player" then
      local d = abs(u.x - enemy.x) + abs(u.y - enemy.y)
      if d < closest_dist then
        closest = u
        closest_dist = d
      end
    end
  end

  if not closest then
    on_done()
    return
  end

  -- find best position to move to
  local best_x, best_y = enemy.x, enemy.y
  local best_dist = closest_dist

  for dy = -enemy.move, enemy.move do
    for dx = -enemy.move, enemy.move do
      if abs(dx) + abs(dy) <= enemy.move then
        local nx, ny = enemy.x + dx, enemy.y + dy
        if grid:is_valid(nx, ny) then
          if not units:at(nx, ny) then
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

  -- move to position
  enemy.x, enemy.y = best_x, best_y
  tween:new(enemy, {tx = enemy.x, ty = enemy.y}, 15, {
    ease = tween.ease.out_quad,
    on_complete = function()
      -- attack if in range
      if best_dist <= enemy.range then
        combat:do_attack(enemy, closest, on_done)
      else
        on_done()
      end
    end
  })
end
