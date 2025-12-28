actions={}

function actions:select_or_menu()
 u=cursor:get_unit()
 tile=cursor:get_tile()
 if tile and tile.type=="spawn" and not u then
  self:show_deploy_menu()
  return
 end
 if u and u.team=="player" and not u.acted then
  game.selected=u
  if u.moved then
   self:show_action_menu()
  else
   game.move_tiles=movement:calc_tiles(u)
   game.fsm:switch"move"
  end
  sfx(1)
 else
  game.selected=nil
  self:show_action_menu()
 end
end

function actions:show_deploy_menu()
 items={}
 for u in all(units.list) do
  if u.team=="player" and not u.deployed then
   add(items,{label=u.name,action=function()
    game.deploy_menu:hide()
    game.deploy_menu=nil
    self:deploy_unit(u)
   end})
  end
 end
 if #items==0 then return end
 game.deploy_menu=menu:new(items,{x=80,y=16})
 game.deploy_menu:show()
end

function actions:deploy_unit(u)
 u.x,u.y=grid.spawn_x,grid.spawn_y
 u.tx,u.ty=grid.spawn_x,grid.spawn_y
 u.deployed,u.moved=true,true
 u.orig_x,u.orig_y=-1,-1
 game.selected=u
 game.move_tiles=movement:calc_tiles(u)
 game.fsm:switch"move"
 sfx(1)
end

function actions:show_action_menu()
 u,items=game.selected,{}
 has_queued=false
 for a in all(game.action_queue) do
  if a.attacker==u then has_queued=true break end
 end
 if u and not u.acted and not has_queued then
  game.attack_tiles=movement:calc_attack_tiles(u,u.x,u.y)
  has_target=false
  for t in all(game.attack_tiles) do
   tgt=units:at(t.x,t.y)
   if tgt and tgt.team=="enemy" then has_target=true break end
  end
  tile=grid:get_tile(u.x,u.y)
  if tile and tile.type=="goal" then
   add(items,{label="escape!",action=function()
    game.action_menu:hide()
    game.action_menu=nil
    game.selected=nil
    game.attack_tiles={}
    game:next_floor()
   end})
  end
  add(items,{label="attack",action=function()
   game.action_menu:hide()
   game.action_menu=nil
   game.fsm:switch"target"
   self:cycle_target(0)
  end,enabled=function()return has_target end})
  add(items,{label="wait",action=function()
   game.action_menu:hide()
   game.action_menu=nil
   u.waiting=true
   game.selected=nil
   game.attack_tiles={}
   game.fsm:switch"select"
  end,enabled=function()return not u.waiting end})
 end
 add(items,{label=function()
  return"execute ("..#game.action_queue..")"
 end,action=function()
  game.action_menu:hide()
  game.action_menu=nil
  game.selected=nil
  game.attack_tiles={}
  game:execute_turn()
 end,enabled=function()return #game.action_queue>0 end})
 add(items,{label="end turn",action=function()
  game.action_menu:hide()
  game.action_menu=nil
  game.selected=nil
  game.attack_tiles={}
  game:execute_and_end_turn()
 end})
 add(items,{label="options",sub_menu=menu:new({
  {label=function()
   return"cam: "..(camera.cam_left and"left"or"right")
  end,action=function()
   camera.cam_left=not camera.cam_left
  end}
 },{x=90,y=26})})

 game.action_menu=menu:new(items,{x=80,y=16,on_cancel=function()
  game.action_menu=nil
  game.attack_tiles={}
  if game.selected then game.selected.waiting=true end
  game.selected=nil
  game.fsm:switch"select"
 end})
 game.action_menu:show()
end

function actions:confirm_move()
 if not grid:tile_in_list(cursor.x,cursor.y,game.move_tiles) then return end
 u=game.selected
 u.x,u.y,u.moved=cursor.x,cursor.y,true
 game.move_tiles={}
 tween:cancel_all(u)
 tween:new(u,{tx=u.x,ty=u.y},10,{ease=tween.ease.out_quad})
 game.fsm:switch"select"
 self:show_action_menu()
 sfx(1)
end

function actions:cancel_move()
 game.selected=nil
 game.attack_tiles={}
 game.fsm:switch"select"
 sfx(0)
end

function actions:cycle_target(dir)
 targets=movement:get_valid_targets(game.attack_tiles)
 if #targets==0 then return end
 cur_idx=1
 for i,t in ipairs(targets) do
  if t.x==cursor.x and t.y==cursor.y then cur_idx=i break end
 end
 new_idx=((cur_idx-1+dir)%#targets)+1
 cursor.x,cursor.y=targets[new_idx].x,targets[new_idx].y
 camera:center(cursor.x,cursor.y)
 sfx(0)
end

function actions:confirm_target()
 if not grid:tile_in_list(cursor.x,cursor.y,game.attack_tiles) then return end
 target=units:at(cursor.x,cursor.y)
 if not target then return end
 add(game.action_queue,{attacker=game.selected,target=target,type="attack"})
 game.selected=nil
 game.attack_tiles={}
 game.fsm:switch"select"
 sfx(1)
end

function actions:cancel_target()
 game.attack_tiles={}
 game.fsm:switch"select"
 self:show_action_menu()
 sfx(0)
end

function actions:try_undo_move()
 u=cursor:get_unit()
 if not(u and u.team=="player" and u.moved and not u.acted) then return end
 if u.orig_x!=-1 and u.orig_y!=-1 then
  blocker=units:at(u.orig_x,u.orig_y)
  if blocker and blocker!=u then sfx(0)return end
 end
 for i=#game.action_queue,1,-1 do
  if game.action_queue[i].attacker==u then deli(game.action_queue,i) end
 end
 game.attack_tiles={}
 u.waiting=false
 if u.orig_x==-1 and u.orig_y==-1 then
  u.deployed,u.moved=false,false
  u.x,u.y,u.tx,u.ty=-1,-1,-1,-1
 else
  u.x,u.y,u.moved=u.orig_x,u.orig_y,false
  tween:cancel_all(u)
  tween:new(u,{tx=u.x,ty=u.y},10,{ease=tween.ease.out_quad})
 end
 sfx(0)
end
