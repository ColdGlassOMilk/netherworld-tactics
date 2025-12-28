-- camera system (optimized with _ENV)
camera=setmetatable({zoom_levels={1,2,3},cam_left=false},{__index=_ENV})
function camera.init(_ENV)
 x,y,rot,rot_tween,zoom,zoom_tween=0,-20,0,0,2,2
 zooming,rotating=false,false
 tween_target=nil
end
function camera.reset(_ENV) rot,rot_tween,rotating=0,0,false end
function camera.center(_ENV,tx,ty,instant)
 local t=camera.calc_pos(camera,tx,ty,rot_tween)
 if instant then x,y=t.x,t.y;tween_target={x=t.x,y=t.y}
 else tween:cancel_all(tween_target or{});tween_target={x=x,y=y}
      tween:new(tween_target,{x=t.x,y=t.y},10,{ease=tween.ease.out_quad}) end
end
function camera.calc_pos(_ENV,px,py,r,z)
 z=z or zoom;local zs=zoom_levels[z];local cx,cy=grid.w/2,grid.h/2
 local rx,ry=px-cx,py-cy;local a=r*0.25;local c,s=cos(a),sin(a)
 rx,ry=rx*c-ry*s+cx,rx*s+ry*c+cy
 local sx,sy=(rx-ry)*grid.tile_w*.5*zs+64,(rx+ry)*grid.tile_h*.5*zs+32
 return {x=64-sx,y=76-sy}
end
function camera.rotate(_ENV,dir)
 if rotating then return end
 rotating=true
 local t=(rot+dir)%4 if t<0 then t=t+4 end
 local tt=rot+dir
 local f=camera.calc_pos(camera,cursor.x,cursor.y,tt)
 tween:cancel_all(tween_target or{});tween_target={x=x,y=y}
 tween:new(camera,{rot_tween=tt},15,{
  ease=tween.ease.out_quad,
  on_complete=function() camera.rot,camera.rot_tween,camera.rotating=t,t,false end
 })
 tween:new(tween_target,f,15,{ease=tween.ease.out_quad})
 sfx(0)
end
function camera.change_zoom(_ENV,dir)
 if zooming then return end
 local nz=zoom+dir if nz<1 or nz>3 then return end
 zooming,zoom=true,nz
 tween:new(camera,{zoom_tween=nz},15,{ease=tween.ease.out_quad,on_complete=function() camera.zooming=false end})
 local f=camera.calc_pos(camera,cursor.x,cursor.y,rot_tween,nz)
 tween:cancel_all(tween_target or{});tween_target={x=x,y=y}
 tween:new(tween_target,f,15,{ease=tween.ease.out_quad})
 sfx(0)
end
function camera.update(_ENV)
 if tween_target then x,y=tween_target.x,tween_target.y end
end
function camera.get_zoom_scale(_ENV)
 local zt=zoom_tween;local z=zoom_levels
 if zt<=1 then return z[1] elseif zt<=2 then return z[1]+(zt-1)*(z[2]-z[1]) else return z[2]+(zt-2)*(z[3]-z[2]) end
end
function camera.iso_pos(_ENV,px,py,h)
 h=h or 0
 local z=camera.get_zoom_scale(camera);local r=rot_tween;local cx,cy=grid.w/2,grid.h/2
 local rx,ry=px-cx,py-cy;local a=r*0.25;local c,s=cos(a),sin(a)
 rx,ry=rx*c-ry*s+cx,rx*s+ry*c+cy
 return (rx-ry)*grid.tile_w*.5*z+64+x,(rx+ry)*grid.tile_h*.5*z+32+y-h*4*z
end
function camera.get_depth(_ENV,px,py)
 local r=rot_tween;local cx,cy=grid.w/2,grid.h/2
 local rx,ry=px-cx,py-cy;local a=r*0.25;local c,s=cos(a),sin(a)
 local nx,ny=rx*c-ry*s+cx,rx*s+ry*c+cy
 return nx+ny
end
