movement={}

function movement:calc_tiles(u)
 tiles={{x=u.x,y=u.y}}
 visited={}
 queue={{x=u.x,y=u.y,cost=0}}
 dirs={{-1,0},{1,0},{0,-1},{0,1}}

 while #queue>0 do
  bi=1
  for i=2,#queue do if queue[i].cost<queue[bi].cost then bi=i end end
  cur=deli(queue,bi)
  k=cur.x..","..cur.y
  if not visited[k] then
   visited[k]=true
   o=units:at(cur.x,cur.y)
   if not (o and o.team!=u.team) then
    if not o and (cur.x!=u.x or cur.y!=u.y) then add(tiles,{x=cur.x,y=cur.y}) end
    for _,d in pairs(dirs) do
     nx,ny=cur.x+d[1],cur.y+d[2]
     if grid:is_valid(nx,ny) then
      nk=nx..","..ny
      if not visited[nk] then
       move_cost=1+max(0,grid:get_height(nx,ny)-grid:get_height(cur.x,cur.y))
       if cur.cost+move_cost<=u.move then add(queue,{x=nx,y=ny,cost=cur.cost+move_cost}) end
      end
     end
    end
   end
  end
 end
 return tiles
end

function movement:calc_attack_tiles(u,x,y)
 tiles={}
 for dy=-u.range,u.range do
  for dx=-u.range,u.range do
   if abs(dx)+abs(dy)<=u.range and (dx!=0 or dy!=0) then
    tx,ty=x+dx,y+dy
    if grid:is_valid(tx,ty) then add(tiles,{x=tx,y=ty}) end
   end
  end
 end
 return tiles
end

function movement:get_valid_targets(at)
  local t = {}
  if not at then return t end  -- prevent nil errors
  for _,v in pairs(at) do     -- pairs works as well, all() not needed
    local u = units:at(v.x,v.y)
    if u and u.team=="enemy" then
      add(t,{x=v.x,y=v.y,unit=u})
    end
  end
  return t
end
