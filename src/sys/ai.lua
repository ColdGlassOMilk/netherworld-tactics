ai={}

function ai:process_enemy(enemy,on_done)
 -- center camera on this enemy first
 camera:center(enemy.x,enemy.y)

 -- delay before starting action (30 frames = ~1 second)
 tween:new({t=0},{t=1},30,{
  on_complete=function()
   self:do_enemy_action(enemy,on_done)
  end
 })
end

function ai:do_enemy_action(enemy,on_done)
 closest,closest_dist=nil,999
 for u in all(units.list) do
  if u.team=="player" and u.deployed then
   d=abs(u.x-enemy.x)+abs(u.y-enemy.y)
   if d<closest_dist then
    closest,closest_dist=u,d
   end
  end
 end

 if not closest then
  -- still wait a moment before moving on
  tween:new({t=0},{t=1},20,{on_complete=on_done})
  return
 end

 best_x,best_y=enemy.x,enemy.y
 best_dist=closest_dist

 for dy=-enemy.move,enemy.move do
  for dx=-enemy.move,enemy.move do
   if abs(dx)+abs(dy)<=enemy.move then
    nx,ny=enemy.x+dx,enemy.y+dy
    if grid:is_valid(nx,ny) and not units:at(nx,ny) then
     d=abs(closest.x-nx)+abs(closest.y-ny)
     if d<best_dist then
      best_dist,best_x,best_y=d,nx,ny
     end
    end
   end
  end
 end

 enemy.x,enemy.y=best_x,best_y

 -- store reference for camera tracking
 self.tracking=enemy

 tween:new(enemy,{tx=enemy.x,ty=enemy.y},15,{
  ease=tween.ease.out_quad,
  on_complete=function()
   self.tracking=nil
   if best_dist<=enemy.range then
    combat:do_attack(enemy,closest,function()
     -- brief pause after attack before next enemy
     tween:new({t=0},{t=1},15,{on_complete=on_done})
    end)
   else
    -- pause before next enemy
    tween:new({t=0},{t=1},20,{on_complete=on_done})
   end
  end
 })
end

function ai:update()
 -- follow tracked enemy during movement
 if self.tracking then
  camera:center(self.tracking.tx,self.tracking.ty)
 end
end
