-- renderer system
renderer = {}

function oline(x1,y1,x2,y2,c)
  line(x1-1,y1,x2-1,y2,0)
  line(x1+1,y1,x2+1,y2,0)
  line(x1,y1-1,x2,y2-1,0)
  line(x1,y1+1,x2,y2+1,0)
  line(x1,y1,x2,y2,c)
end

function diamond(sx,sy,hw,hh,c)
  for i=0,hh do local w=hw*(hh-i)/hh
    line(sx-w,sy-i,sx+w,sy-i,c)
    line(sx-w,sy+i,sx+w,sy+i,c)
  end
end

function renderer:draw_all()
  local dl={}
  for y=0,grid.h-1 do for x=0,grid.w-1 do
    add(dl,{t="tile",x=x,y=y,d=grid:get_tile_depth(x,y)})
  end end
  for u in all(units.list) do if u.x>=0 then
    local ux,uy=flr(u.tx+0.5),flr(u.ty+0.5)
    add(dl,{t="unit",u=u,d=grid:get_tile_depth(ux,uy)+0.01})
  end end
  for i=1,#dl-1 do for j=i+1,#dl do
    if dl[j].d<dl[i].d then dl[i],dl[j]=dl[j],dl[i] end
  end end
  for item in all(dl) do
    if item.t=="tile" then self:draw_tile(item.x,item.y)
    else self:draw_unit(item.u) end
  end
  self:draw_cursor()
  if game.show_markers then self:draw_markers() end
end

function renderer:draw_tile(x,y)
  local tile=grid:get_tile(x,y) if not tile then return end
  local h=tile.height
  local sx,sy=camera:iso_pos(x,y,h)
  local z=camera:get_zoom_scale()
  local hw,hh=(grid.tile_w/2)*z,(grid.tile_h/2)*z
  local hpx=h*4*z
  local c=tile.col
  if grid:tile_in_list(x,y,game.move_tiles or{}) then c=12
  elseif grid:tile_in_list(x,y,game.attack_tiles or{}) then c=8 end
  local sl,sr=0,0
  if c==1 then sl,sr=0,0 elseif c==2 then sl,sr=1,0
  elseif c==13 then sl,sr=2,1 elseif c==12 then sl,sr=1,0
  elseif c==8 then sl,sr=2,0 else sl,sr=max(0,c-1),max(0,c-2) end
  if h>0 then for i=0,hpx do
    line(sx-hw,sy+i,sx,sy+hh+i,sl)line(sx,sy+hh+i,sx+hw,sy+i,sr)
  end end
  diamond(sx,sy,hw,hh,c)
  if tile.type=="spawn"or tile.type=="goal" then
    local t=(time()*0.7)%1
    local ph=t<0.5 and t*2 or (1-t)*2
    local c1,c2=0,0
    if tile.type=="spawn" then c1,c2=13,12 else c1,c2=8,9 end
    if ph>0.66 then diamond(sx,sy,hw*0.6,hh*0.6,c1)diamond(sx,sy,hw*0.3,hh*0.3,c2)
    elseif ph>0.33 then diamond(sx,sy,hw*0.3,hh*0.3,c2) end
  end
  line(sx,sy-hh,sx+hw,sy,0)
  line(sx+hw,sy,sx,sy+hh,0)
  line(sx,sy+hh,sx-hw,sy,0)
  line(sx-hw,sy,sx,sy-hh,0)
  if h>0 then
    line(sx-hw,sy,sx-hw,sy+hpx,0)
    line(sx+hw,sy,sx+hw,sy+hpx,0)
    line(sx-hw,sy+hpx,sx,sy+hh+hpx,0)
    line(sx,sy+hh+hpx,sx+hw,sy+hpx,0)
  end
end

function renderer:draw_unit(u)
  if not u or u.tx==nil then return end
  local h=grid:get_height(flr(u.tx+0.5),flr(u.ty+0.5))
  local sx,sy=camera:iso_pos(u.tx,u.ty,h)
  local z=camera:get_zoom_scale()
  local spr_id=sprites:get_sprite(u)
  local sw,sh=16*z,16*z
  local spr_x=(spr_id%8)*16
  local spr_y=flr(spr_id/8)*16
  ovalfill(sx-4*z,sy-3,sx+4*z,sy+1*z+1,0)
  sspr(spr_x,spr_y,16,16,sx-sw/2,sy-sh,sw,sh)
  if u.hp<u.max_hp then
    local bw,by=12*z,sy-sh-3*z
    rectfill(sx-bw/2-1,by-1,sx+bw/2+1,by+1,0)
    line(sx-bw/2,by,sx+bw/2,by,5)
    local hc=u.team=="player"and 11 or 8
    local fw=bw*u.hp/u.max_hp
    if fw>0 then line(sx-bw/2,by,sx-bw/2+fw,by,hc) end
  end
  if u.team=="player"and u.acted then
    local zy=sy-sh-3*z
    print("z",sx-1,zy,5)print("z",sx+2,zy-2,6)
  end
end

function renderer:draw_cursor()
  local p=game.fsm.current if p=="enemy"or p=="execute"then return end
  local cx,cy=cursor.x,cursor.y
  if not grid:get_tile(cx,cy) then return end
  local h=grid:get_height(cx,cy)
  local sx,sy=camera:iso_pos(cx,cy,h)
  local z=camera:get_zoom_scale()
  local e=1+sin(time()*3)*0.15
  local hw,hh=(grid.tile_w/2)*z*e,(grid.tile_h/2)*z*e
  local len,l=2*z,z
  local cd=camera:get_depth(cx,cy)
  local function occ(dx,dy)
    local ax,ay=cx+dx,cy+dy
    if not grid:is_valid(ax,ay) then return false end
    return camera:get_depth(ax,ay)>cd and grid:get_height(ax,ay)>h
  end
  local rot=flr(camera.rot_tween+0.5)%4
  local d=({{1,0,0,1},{0,1,-1,0},{-1,0,0,-1},{0,-1,1,0}})[rot+1]
  if not units:at(cx,cy) then
    oline(sx,sy-hh,sx-len,sy-hh+l,10)oline(sx,sy-hh,sx+len,sy-hh+l,10)
  end
  if not occ(d[1],d[2]) then
    oline(sx+hw,sy,sx+hw-len,sy-l,10)oline(sx+hw,sy,sx+hw-len,sy+l,10)
  end
  if not occ(d[1]+d[3],d[2]+d[4]) then
    oline(sx,sy+hh,sx-len,sy+hh-l,10)oline(sx,sy+hh,sx+len,sy+hh-l,10)
  end
  if not occ(d[3],d[4]) then
    oline(sx-hw,sy,sx-hw+len,sy-l,10)oline(sx-hw,sy,sx-hw+len,sy+l,10)
  end
end

function renderer:draw_markers()
  local mk={{x=grid.spawn_x,y=grid.spawn_y,col=12},{x=grid.goal_x,y=grid.goal_y,col=9}}
  local ol={{0,-7},{1,-6},{2,-5,-4},{3,-3,-2,-1},{4,0,1},{3,2,3,4},{2,5,6},{1,7},{0,8}}
  for m in all(mk) do
    local h=grid:get_height(m.x,m.y)
    local sx,sy=camera:iso_pos(m.x,m.y,h)
    local cy=sy-18+sin(time()*2)*2
    for o in all(ol) do local w=o[1]
      for i=2,#o do pset(sx-w,cy+o[i],0)if w>0 then pset(sx+w,cy+o[i],0) end end
    end
    pset(sx,cy-6,m.col)
    rectfill(sx-1,cy-5,sx+1,cy-4,m.col)
    rectfill(sx-2,cy-3,sx+2,cy-1,m.col)
    rectfill(sx-3,cy,sx+3,cy+1,m.col)
    rectfill(sx-2,cy+2,sx+2,cy+4,m.col)
    rectfill(sx-1,cy+5,sx+1,cy+6,m.col)
    pset(sx,cy+7,m.col)
  end
end
