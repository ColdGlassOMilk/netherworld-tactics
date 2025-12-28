combat={}

function combat:calc_damage(a,t)
 ah,dh=grid:get_height(a.x,a.y),grid:get_height(t.x,t.y)
 hd=ah-dh
 ha=max(0,hd*2)
 hd_bonus=max(0,-hd)
 chain=0
 for u in all(units.list) do
  if u!=a and u.team==a.team then
   d=abs(u.x-t.x)+abs(u.y-t.y)
   if d<=u.range then chain+=flr(u.atk/2) end
  end
 end
 return max(1,a.atk+chain+ha-(t.def+hd_bonus))
end

function combat:do_attack(a,t,on_done)
 dmg=self:calc_damage(a,t)

 ox,oy=a.tx,a.ty
 dx,dy=(t.x-a.x)*0.3,(t.y-a.y)*0.3

 sprites:play(a,"attack")
 tween:new(a,{tx=ox+dx,ty=oy+dy},6,{
  ease=tween.ease.out_quad,
  on_complete=function()
   t.hp-=dmg
   sfx(2)
   sprites:play(t,"hurt",function()sprites:play(t,"idle")end)
   tween:new(a,{tx=ox,ty=oy},8,{
    ease=tween.ease.out_back,
    on_complete=function()
     sprites:play(a,"idle")
     if not units:check_dead() and on_done then on_done() end
    end
   })
  end
 })
end
