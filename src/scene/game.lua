-- game scene

game = {
  -- floor = 1,
  -- message = "",
  -- msg_timer = 0,
  -- action_queue = {},
  -- enemy_queue = {},
  -- selected = nil,
  -- move_tiles = {},
  -- attack_tiles = {},
  -- action_menu = nil,
  -- deploy_menu = nil
}

function game:init()
  self.floor = 1
  self.action_queue = {}
  camera:init()
  grid:init()
  units:init()
  cursor:init()
  grid:generate()
  units:spawn_enemies(self.floor)
  cursor.x, cursor.y = grid.spawn_x, grid.spawn_y
  camera:center(cursor.x, cursor.y, true)
  self:init_states()
  self:start_player_phase()
end

function game:init_states()
 self.fsm=state:new({
  select={
   bindings={
    [0]=function()
     if btn(4) then camera:rotate(1)game.did_rotate=true
     else cursor:move(-1,0)end
    end,
    [1]=function()
     if btn(4) then camera:rotate(-1)game.did_rotate=true
     else cursor:move(1,0)end
    end,
    [2]=function()
     if btn(4) then camera:change_zoom(1)game.did_zoom=true
     else cursor:move(0,-1)end
    end,
    [3]=function()
     if btn(4) then camera:change_zoom(-1)game.did_zoom=true
     else cursor:move(0,1)end
    end,
    [4]=function()
     if not(game.did_rotate or game.did_zoom)then
      actions:try_undo_move()
     end
     game.did_rotate,game.did_zoom=false,false
    end,
    [5]=function()actions:select_or_menu()end
   },
   init=function()game.did_rotate,game.did_zoom=false,false end
  },
  move={
   bindings={
    [0]=function()cursor:move(-1,0)end,
    [1]=function()cursor:move(1,0)end,
    [2]=function()cursor:move(0,-1)end,
    [3]=function()cursor:move(0,1)end,
    [4]=function()actions:cancel_move()end,
    [5]=function()actions:confirm_move()end
   },
   exit=function()game.move_tiles={}end
  },
  target={
   bindings={
    [0]=function()actions:cycle_target(-1)end,
    [1]=function()actions:cycle_target(1)end,
    [2]=function()actions:cycle_target(-1)end,
    [3]=function()actions:cycle_target(1)end,
    [4]=function()actions:cancel_target()end,
    [5]=function()actions:confirm_target()end
   },
   exit=function()game.attack_tiles={}end
  },
  execute={},
  enemy={},
  gameover={
   bindings={
    [5]=function()
     game.floor=1
     units.list={}
     game:init()
    end
   }
  }
 },"select")
end

function game:start_player_phase()
 self.selected,self.action_menu,self.deploy_menu=nil
 self.move_tiles,self.attack_tiles,self.action_queue={},{},{}
 for u in all(units.list) do
  if u.team=="player" then
   u.acted,u.moved,u.waiting=false,false,false
   u.orig_x=u.deployed and u.x or -1
   u.orig_y=u.deployed and u.y or -1
  end
 end
 self:msg"player turn"
 self.fsm:switch"select"
end

function game:start_enemy_phase()
 self:msg"enemy turn"
 self.fsm:switch"enemy"
 self.enemy_queue={}
 for u in all(units.list) do
  if u.team=="enemy" then add(self.enemy_queue,u) end
 end
 self:process_next_enemy()
end

function game:process_next_enemy()
 if #self.enemy_queue==0 then
  self:start_player_phase()
  return
 end
 ai:process_enemy(deli(self.enemy_queue,1),function()
  self:process_next_enemy()
 end)
end

function game:execute_turn()
 if #self.action_queue==0 then
  self.fsm:switch"select"
  return
 end
 for a in all(self.action_queue) do
  if a.attacker and a.attacker.team=="player" then
   a.attacker.acted=true
  end
 end
 self.end_turn_after=false
 self.fsm:switch"execute"
 self:process_next_action()
end

function game:execute_and_end_turn()
 for u in all(units.list) do
  if u.team=="player" and u.moved then u.acted=true end
 end
 if #self.action_queue==0 then
  self:start_enemy_phase()
  return
 end
 self.end_turn_after=true
 self.fsm:switch"execute"
 self:process_next_action()
end

function game:process_next_action()
 if #self.action_queue==0 then
  if self.end_turn_after then self:start_enemy_phase()
  else self.fsm:switch"select" end
  return
 end
 local a=deli(self.action_queue,1)
 if a.type=="attack" then
  combat:do_attack(a.attacker,a.target,function()
   self:process_next_action()
  end)
 end
end

function game:next_floor()
 self.floor+=1
 self:msg("floor "..self.floor.."!")
 for u in all(units.list) do
  if u.team=="player" then
   u.hp=min(u.hp+5,u.max_hp)
  end
 end
 tween:new({t=0},{t=1},60,{
  on_complete=function()
   for i=#units.list,1,-1 do
    if units.list[i].team=="enemy" then
     deli(units.list,i)
    end
   end
   grid:generate()
   units:spawn_enemies(self.floor)
   camera:reset()
   cursor.x,cursor.y=grid.spawn_x,grid.spawn_y
   camera:center(cursor.x,cursor.y,true)
   self:start_player_phase()
  end
 })
end

function game:game_over()
 self:msg("game over - floor "..self.floor)
 self.fsm:switch"gameover"
end

function game:msg(t)
 self.message=t
 self.msg_timer=45
end

function game:update()
 if self.msg_timer>0 then self.msg_timer-=1 end
 camera:update()
 sprites:update_all()
 if btn(4) then
  self.o_hold_time=min((self.o_hold_time or 0)+1,15)
 else
  self.o_hold_time=0
 end
 self.show_markers=self.o_hold_time>=15
end

function game:draw()
 pal()
 cls()
 renderer:draw_all()
 ui:draw()
 if self.action_menu then self.action_menu:draw() end
 if self.deploy_menu then self.deploy_menu:draw() end

 pal(1,129,1)
 pal(2,130,1)
 pal(13,141,1)
 pal(12,131,1)
 pal(8,136,1)
 pal(11,139,1)
 pal(3,133,1)
 pal(9,137,1)
 pal(10,135,1)
 pal(14,142,1)
 pal(15,143,1)
 pal(5,133,1)
 pal(6,134,1)
end
