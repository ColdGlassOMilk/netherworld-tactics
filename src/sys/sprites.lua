-- sprite animation system

sprites = {
  -- animation definitions per unit type
  -- each anim is {start_sprite, frame_count, speed, loop}
  -- 16x16 sprites: 8 sprites per row (128/16=8)
  anims = {
    -- player warrior (vex) - row 0 (sprites 0-7)
    vex = {
      idle = {0, 2, 0.1, true},      -- 2 frames, slow bob
      move = {2, 2, 0.2, true},      -- 2 frames, walking
      attack = {4, 2, 0.25, false},  -- 2 frames, slash
      hurt = {6, 1, 0.2, false},     -- 1 frame, flinch
      dead = {7, 1, 0, false}        -- 1 frame, fallen
    },
    -- player mage (nyx) - row 1 (sprites 8-15)
    nyx = {
      idle = {8, 2, 0.1, true},
      move = {10, 2, 0.2, true},
      attack = {12, 2, 0.25, false},
      hurt = {14, 1, 0.2, false},
      dead = {15, 1, 0, false}
    },
    -- enemy imp - row 2 (sprites 16-23)
    imp = {
      idle = {16, 2, 0.15, true},
      move = {18, 2, 0.2, true},
      attack = {20, 2, 0.25, false},
      hurt = {22, 1, 0.2, false},
      dead = {23, 1, 0, false}
    }
  }
}

function sprites:init_unit(u)
  u.anim = "idle"
  u.anim_frame = 0
  u.anim_timer = 0
  u.anim_done = false
end

function sprites:play(u, anim_name, on_complete)
  local anims = self.anims[u.name]
  if not anims or not anims[anim_name] then
    -- fallback: just set anim name, get_sprite will handle missing
    u.anim = anim_name
    if on_complete then on_complete() end
    return
  end

  u.anim = anim_name
  u.anim_frame = 0
  u.anim_timer = 0
  u.anim_done = false
  u.anim_callback = on_complete
end

function sprites:update(u)
  local anims = self.anims[u.name]
  if not anims then return end

  local anim = anims[u.anim]
  if not anim then return end

  local start, count, speed, loop = anim[1], anim[2], anim[3], anim[4]

  if u.anim_done then return end

  u.anim_timer += speed
  if u.anim_timer >= 1 then
    u.anim_timer -= 1
    u.anim_frame += 1

    if u.anim_frame >= count then
      if loop then
        u.anim_frame = 0
      else
        u.anim_frame = count - 1
        u.anim_done = true
        if u.anim_callback then
          u.anim_callback()
          u.anim_callback = nil
        end
      end
    end
  end
end

function sprites:get_sprite(u)
  local anims = self.anims[u.name]
  if not anims then return 0 end

  local anim = anims[u.anim or "idle"]
  if not anim then
    -- fallback to idle
    anim = anims["idle"]
    if not anim then return 0 end
  end

  return anim[1] + (u.anim_frame or 0)
end

function sprites:update_all()
  for u in all(units.list) do
    self:update(u)
  end
end
