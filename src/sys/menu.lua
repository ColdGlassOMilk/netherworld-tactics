-- menu system
menu = {}
menu.__index = menu
function menu:new(items, opts)
  opts = opts or {}
  return setmetatable({
    items = items or {}, sel = 1, active = false,
    x = opts.x or 80, y = opts.y or 20,
    parent = nil, closeable = opts.closeable != false,
    on_cancel = opts.on_cancel
  }, self)
end
function menu:show(parent)
  self.sel, self.active, self.parent = 1, true, parent
  input:push()
  input:bind({
    [2] = function() self:nav(-1) end,
    [3] = function() self:nav(1) end,
    [4] = function() if self.closeable then self:cancel() end end,
    [5] = function() self:select() end
  })
  sfx(6)
end
function menu:hide()
  if not self.active then return end
  self.active = false
  input:pop()
  sfx(7)
end
function menu:cancel()
  self:hide()
  if self.on_cancel then self.on_cancel() end
end
function menu:nav(dir)
  self.sel = ((self.sel - 1 + dir) % #self.items) + 1
  sfx(5)
end
function menu:is_enabled(it)
  if type(it.enabled) == "function" then return it.enabled() end
  return it.enabled != false
end
function menu:get_label(it)
  if type(it.label) == "function" then return it.label() end
  return it.label
end
function menu:select()
  local it = self.items[self.sel]
  if not self:is_enabled(it) then return end
  if it.sub_menu then
    it.sub_menu:show(self)
  elseif it.action then
    sfx(1)
    if it.action() then
      self:hide()
      if self.parent and self.parent.active then
        self.parent:hide()
      end
    end
  end
end
function menu:draw()
  if not self.active then return end
  local w = 44
  for _, it in pairs(self.items) do
    w = max(w, #self:get_label(it) * 4 + 14)
  end
  local h = #self.items * 10 + 3
  local dx, dy = mid(1, self.x, 127 - w), mid(1, self.y, 127 - h)
  local it = self.items[self.sel]
  local sub_active = it.sub_menu and it.sub_menu.active
  rectfill(dx, dy, dx + w, dy + h, 0)
  rectfill(dx, dy, dx + w, dy + 1, 2)
  rect(dx, dy, dx + w, dy + h, 2)
  for i, it in ipairs(self.items) do
    local lbl, iy = self:get_label(it), dy + 5 + (i - 1) * 10
    local en = self:is_enabled(it)
    if i == self.sel then
      rectfill(dx + 1, iy - 2, dx + w - 1, iy + 6, 2)
      print(lbl, dx + 8, iy, en and 10 or 5)
      if not sub_active then
        spr(238, dx - 12 + sin(time() * 3) * 2, iy - 1, 2, 2)
      end
    else
      print(lbl, dx + 8, iy, en and 13 or 5)
    end
  end
  if sub_active then it.sub_menu:draw() end
end
