grid={w=10,h=10,tile_w=16,tile_h=8,spawn_x=0,spawn_y=0,goal_x=0,goal_y=0}

function grid:init() self.tiles={} end

function grid:generate()
 self.tiles={}
 for y=0,self.h-1 do
  self.tiles[y]={}
  for x=0,self.w-1 do
   r=rnd()
   h=r>0.75 and 2 or r>0.4 and 1 or 0
   c=h==0 and 1 or h==1 and 2 or 13
   self.tiles[y][x]={height=h,col=c,type="normal"}
  end
 end

 self.spawn_x,self.spawn_y=flr(rnd(self.w)),flr(rnd(self.h))
 t=self.tiles[self.spawn_y][self.spawn_x]
 t.height,t.col,t.type=0,1,"spawn"

 repeat gx,gy=flr(rnd(self.w)),flr(rnd(self.h))
 until(gx!=self.spawn_x or gy!=self.spawn_y) and abs(gx-self.spawn_x)+abs(gy-self.spawn_y)>=4
 t=self.tiles[gy][gx]
 t.height,t.col,t.type=0,2,"goal"
 self.goal_x,self.goal_y=gx,gy

 for u in all(units.list) do
  if u.team=="player" then
   u.deployed=false
   u.x,u.y,u.tx,u.ty=-1,-1,-1,-1
  end
 end
end

function grid:get_tile(x,y)
 if x<0 or x>=self.w or y<0 or y>=self.h then return nil end
 local row = self.tiles[y]
 return row and row[x]
end

function grid:get_height(x,y)
 local t = self:get_tile(x,y)
 return t and t.height or 0
end

function grid:get_tile_depth(x,y)
 return camera:get_depth(x,y)+self:get_height(x,y)*0.5
end

function grid:is_valid(x,y)
 return x>=0 and x<self.w and y>=0 and y<self.h
end

function grid:tile_in_list(x,y,l)
 for t in all(l) do if t.x==x and t.y==y then return true end end
 return false
end
