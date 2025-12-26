-- combat system

combat = {}

function combat:do_attack(attacker, target, on_done)
  local atk_h = grid:get_height(attacker.x, attacker.y)
  local def_h = grid:get_height(target.x, target.y)

  local height_diff = atk_h - def_h
  local height_atk_bonus = max(0, height_diff * 2)
  local height_def_bonus = max(0, -height_diff * 1)

  -- chain bonus from nearby allies
  local chain_bonus = 0
  for u in all(units.list) do
    if u != attacker and u.team == attacker.team then
      local dist = abs(u.x - target.x) + abs(u.y - target.y)
      if dist <= u.range then
        chain_bonus += flr(u.atk / 2)
      end
    end
  end

  local total_atk = attacker.atk + chain_bonus + height_atk_bonus
  local total_def = target.def + height_def_bonus
  local dmg = max(1, total_atk - total_def)

  -- lunge animation
  local ox, oy = attacker.tx, attacker.ty
  local dx = (target.x - attacker.x) * 0.3
  local dy = (target.y - attacker.y) * 0.3

  tween:new(attacker, {tx = ox + dx, ty = oy + dy}, 6, {
    ease = tween.ease.out_quad,
    on_complete = function()
      target.hp -= dmg
      sfx(2)

      -- build message
      local msg = dmg .. " dmg!"
      if chain_bonus > 0 then msg = msg .. " chain+" end
      if height_diff > 0 then msg = msg .. " high+"
      elseif height_diff < 0 then msg = msg .. " low-" end
      game:msg(msg)

      -- return animation
      tween:new(attacker, {tx = ox, ty = oy}, 8, {
        ease = tween.ease.out_back,
        on_complete = function()
          local transitioned = units:check_dead()
          if not transitioned and on_done then
            on_done()
          end
        end
      })
    end
  })
end

function combat:calc_damage(attacker, target)
  local atk_h = grid:get_height(attacker.x, attacker.y)
  local def_h = grid:get_height(target.x, target.y)

  local height_diff = atk_h - def_h
  local height_atk_bonus = max(0, height_diff * 2)
  local height_def_bonus = max(0, -height_diff * 1)

  local chain_bonus = 0
  for u in all(units.list) do
    if u != attacker and u.team == attacker.team then
      local dist = abs(u.x - target.x) + abs(u.y - target.y)
      if dist <= u.range then
        chain_bonus += flr(u.atk / 2)
      end
    end
  end

  local total_atk = attacker.atk + chain_bonus + height_atk_bonus
  local total_def = target.def + height_def_bonus

  return max(1, total_atk - total_def)
end
