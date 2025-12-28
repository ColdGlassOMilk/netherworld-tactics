bindings={}

function bindings:bind_select()
 self.did_rotate,self.did_zoom=false,false
 input:bind({
  [0]=function()
   if btn(4) then camera:rotate(1)self.did_rotate=true
   else cursor:move(-1,0)end
  end,
  [1]=function()
   if btn(4) then camera:rotate(-1)self.did_rotate=true
   else cursor:move(1,0)end
  end,
  [2]=function()
   if btn(4) then camera:change_zoom(1)self.did_zoom=true
   else cursor:move(0,-1)end
  end,
  [3]=function()
   if btn(4) then camera:change_zoom(-1)self.did_zoom=true
   else cursor:move(0,1)end
  end,
  [4]=function()
   if not(self.did_rotate or self.did_zoom)then
    actions:try_undo_move()
   end
   self.did_rotate,self.did_zoom=false,false
  end,
  [5]=function()actions:select_or_menu()end
 })
end

function bindings:bind_move()
 input:bind({
  [0]=function()cursor:move(-1,0)end,
  [1]=function()cursor:move(1,0)end,
  [2]=function()cursor:move(0,-1)end,
  [3]=function()cursor:move(0,1)end,
  [4]=function()actions:cancel_move()end,
  [5]=function()actions:confirm_move()end
 })
end

function bindings:bind_action_menu()
 input:bind({
  [2]=function()if game.action_menu then game.action_menu:nav(-1)end end,
  [3]=function()if game.action_menu then game.action_menu:nav(1)end end,
  [4]=function()actions:cancel_action()end,
  [5]=function()if game.action_menu then game.action_menu:select()end end
 })
end

function bindings:bind_target()
 input:bind({
  [0]=function()actions:cycle_target(-1)end,
  [1]=function()actions:cycle_target(1)end,
  [2]=function()actions:cycle_target(-1)end,
  [3]=function()actions:cycle_target(1)end,
  [4]=function()actions:cancel_target()end,
  [5]=function()actions:confirm_target()end
 })
end

function bindings:bind_deploy_menu()
 input:bind({
  [2]=function()if game.deploy_menu then game.deploy_menu:nav(-1)end end,
  [3]=function()if game.deploy_menu then game.deploy_menu:nav(1)end end,
  [4]=function()
   if game.deploy_menu then
    game.deploy_menu:hide()
    game.deploy_menu=nil
   end
   game.phase="select"
   bindings:bind_select()
  --  sfx(0)
  end,
  [5]=function()if game.deploy_menu then game.deploy_menu:select()end end
 })
end

function bindings:bind_options_menu()
 input:bind({
  [2]=function()
   if game.options_menu and game.options_menu.active then
    game.options_menu:nav(-1)
   end
  end,
  [3]=function()
   if game.options_menu and game.options_menu.active then
    game.options_menu:nav(1)
   end
  end,
  [4]=function()
   if game.options_menu then game.options_menu:hide()end
   bindings:bind_action_menu()
  --  sfx(0)
  end,
  [5]=function()
   if game.options_menu and game.options_menu.active then
    game.options_menu:select()
   end
  end
 })
end
