-- sprite animation system
sprites={
  anims={
    vex={idle={0,2,0.1,true}, move={2,2,0.2,true}, attack={4,2,0.25,false}, hurt={6,1,0.2,false}, dead={7,1,0,false}},
    nyx={idle={8,2,0.1,true}, move={10,2,0.2,true}, attack={12,2,0.25,false}, hurt={14,1,0.2,false}, dead={15,1,0,false}},
    imp={idle={16,2,0.15,true}, move={18,2,0.2,true}, attack={20,2,0.25,false}, hurt={22,1,0.2,false}, dead={23,1,0,false}}
  }
}

function sprites:init_unit(u)
  u.anim,u.anim_frame,u.anim_timer,u.anim_done= "idle",0,0,false
end

function sprites:play(u,a,cb)
  local anim=self.anims[u.name]
  if not anim or not anim[a] then u.anim=a if cb then cb() end return end
  u.anim = a
  u.anim_frame, u.anim_timer = 0, 0
  u.anim_done, u.anim_callback = false, cb
end

function sprites:update(u)
  local anims=self.anims[u.name]
  if not anims then return end
  local anim=anims[u.anim]
  if not anim or u.anim_done then return end
  local s,c,spd,loop=anim[1],anim[2],anim[3],anim[4]
  u.anim_timer+=spd
  if u.anim_timer>=1 then
    u.anim_timer-=1
    u.anim_frame+=1
    if u.anim_frame>=c then
      if loop then u.anim_frame=0 else u.anim_frame=c-1 u.anim_done=true if u.anim_callback then u.anim_callback() u.anim_callback=nil end end
    end
  end
end

function sprites:get_sprite(u)
  local anims=self.anims[u.name]
  if not anims then return 0 end
  local anim=anims[u.anim or "idle"] or anims["idle"]
  return anim[1]+(u.anim_frame or 0)
end

function sprites:update_all()
  for u in all(units.list) do self:update(u) end
end
