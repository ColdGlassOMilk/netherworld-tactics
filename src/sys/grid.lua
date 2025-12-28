grid=setmetatable({w=10,h=10,tile_w=16,tile_h=8,spawn_x=0,spawn_y=0,goal_x=0,goal_y=0},{__index=_ENV})
function grid.init(_ENV) tiles={} end
function grid.generate(_ENV)
 tiles={}
 for py=0,h-1 do
  tiles[py]={}
  for px=0,w-1 do
   r=rnd()
   ht=r>0.75 and 2 or r>0.4 and 1 or 0
   c=ht==0 and 1 or ht==1 and 2 or 13
   tiles[py][px]={height=ht,col=c,type="normal"}
  end
 end
 spawn_x,spawn_y=flr(rnd(w)),flr(rnd(h))
 t=tiles[spawn_y][spawn_x]
 t.height,t.col,t.type=0,1,"spawn"
 repeat gx,gy=flr(rnd(w)),flr(rnd(h))
 until(gx!=spawn_x or gy!=spawn_y) and abs(gx-spawn_x)+abs(gy-spawn_y)>=4
 t=tiles[gy][gx]
 t.height,t.col,t.type=0,2,"goal"
 goal_x,goal_y=gx,gy
 for u in all(units.list) do
  if u.team=="player" then
   u.deployed=false
   u.x,u.y,u.tx,u.ty=-1,-1,-1,-1
  end
 end
end
function grid.get_tile(_ENV,px,py)
 if px<0 or px>=w or py<0 or py>=h then return nil end
 local row=tiles[py]
 return row and row[px]
end
function grid.get_height(_ENV,px,py)
 local t=grid.get_tile(_ENV,px,py)
 return t and t.height or 0
end
function grid.get_tile_depth(_ENV,px,py)
 return camera:get_depth(px,py)+grid.get_height(_ENV,px,py)*0.5
end
function grid.is_valid(_ENV,px,py)
 return px>=0 and px<w and py>=0 and py<h
end
function grid.tile_in_list(_ENV,px,py,l)
 for t in all(l) do if t.x==px and t.y==py then return true end end
 return false
end
