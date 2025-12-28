-- camera system (optimized)

camera={zoom_levels={1,2,3},cam_left=false}

function camera:init()
 self.x,self.y,self.rot,self.rot_tween,self.zoom,self.zoom_tween=0,-20,0,0,2,2
 self.zooming,self.rotating=false,false
 self.tween_target=nil
end

function camera:reset() self.rot,self.rot_tween,self.rotating=0,0,false end

function camera:center(x,y,instant)
 local t=self:calc_pos(x,y,self.rot_tween)
 if instant then self.x,self.y=t.x,t.y;self.tween_target={x=t.x,y=t.y}
 else tween:cancel_all(self.tween_target or{});self.tween_target={x=self.x,y=self.y}
      tween:new(self.tween_target,{x=t.x,y=t.y},10,{ease=tween.ease.out_quad}) end
end

function camera:calc_pos(x,y,rot,zoom)
 zoom=zoom or self.zoom;local z=self.zoom_levels[zoom];local cx,cy=grid.w/2,grid.h/2
 local rx,ry=x-cx,y-cy;local a=rot*0.25;local c,s=cos(a),sin(a)
 rx,ry=rx*c-ry*s+cx,rx*s+ry*c+cy
 local sx,sy=(rx-ry)*grid.tile_w*.5*z+64,(rx+ry)*grid.tile_h*.5*z+32
 return {x=64-sx,y=64-sy}
end

function camera:rotate(dir)
 if self.rotating then return end
 self.rotating=true
 local t=(self.rot+dir)%4 if t<0 then t=t+4 end
 local tt=self.rot+dir
 local f=self:calc_pos(cursor.x,cursor.y,tt)
 tween:cancel_all(self.tween_target or{});self.tween_target={x=self.x,y=self.y}
 tween:new(self,{rot_tween=tt},15,{
  ease=tween.ease.out_quad,
  on_complete=function() self.rot,self.rot_tween,self.rotating=t,t,false end
 })
 tween:new(self.tween_target,f,15,{ease=tween.ease.out_quad})
 sfx(0)
end

function camera:change_zoom(dir)
 if self.zooming then return end
 local nz=self.zoom+dir if nz<1 or nz>3 then return end
 self.zooming,self.zoom=true,nz
 tween:new(self,{zoom_tween=nz},15,{ease=tween.ease.out_quad,on_complete=function() self.zooming=false end})
 local f=self:calc_pos(cursor.x,cursor.y,self.rot_tween,nz)
 tween:cancel_all(self.tween_target or{});self.tween_target={x=self.x,y=self.y}
 tween:new(self.tween_target,f,15,{ease=tween.ease.out_quad})
 sfx(0)
end

function camera:update()
 if self.tween_target then self.x,self.y=self.tween_target.x,self.tween_target.y end
end

function camera:get_zoom_scale()
 local zt=self.zoom_tween;local z=self.zoom_levels
 if zt<=1 then return z[1] elseif zt<=2 then return z[1]+(zt-1)*(z[2]-z[1]) else return z[2]+(zt-2)*(z[3]-z[2]) end
end

function camera:iso_pos(x,y,h)
 h=h or 0
 local z=self:get_zoom_scale();local rot=self.rot_tween;local cx,cy=grid.w/2,grid.h/2
 local rx,ry=x-cx,y-cy;local a=rot*0.25;local c,s=cos(a),sin(a)
 rx,ry=rx*c-ry*s+cx,rx*s+ry*c+cy
 return (rx-ry)*grid.tile_w*.5*z+64+self.x,(rx+ry)*grid.tile_h*.5*z+32+self.y-h*4*z
end

function camera:get_depth(x,y)
 local rot=self.rot_tween;local cx,cy=grid.w/2,grid.h/2
 local rx,ry=x-cx,y-cy;local a=rot*0.25;local c,s=cos(a),sin(a)
 local nx,ny=rx*c-ry*s+cx,rx*s+ry*c+cy
 return nx+ny
end
