-- menu system

menu = {}
menu.__index = menu

function menu:new(items, opts)
  opts = opts or {}
  m = {
    items = items or {},
    sel = 1,
    active = false,
    x = opts.x or 80,
    y = opts.y or 20,
    parent = nil,
    closeable = opts.closeable != false,
    on_cancel = opts.on_cancel
  }
  return setmetatable(m, self)
end

function menu:show(parent)
  self.sel = 1
  self.active = true
  self.parent = parent
  input:push()
  self:_bind()
  sfx(0)
end

function menu:_bind()
  input:bind({
    [2] = function() self:nav(-1) end,
    [3] = function() self:nav(1) end,
    [4] = function() if self.closeable then self:cancel() end end,
    [5] = function() self:select() end
  })
end

function menu:hide()
  if not self.active then return end
  self.active = false
  input:pop()
  sfx(0)
end

function menu:cancel()
  self:hide()
  if self.on_cancel then self.on_cancel() end
end

function menu:nav(dir)
  self.sel = ((self.sel - 1 + dir) % #self.items) + 1
  sfx(0)
end

function menu:is_enabled(item)
  if type(item.enabled) == "function" then return item.enabled() end
  return item.enabled != false
end

function menu:get_label(item)
  if type(item.label) == "function" then return item.label() end
  return item.label
end

function menu:select()
  item = self.items[self.sel]
  if not self:is_enabled(item) then return end
  if item.sub_menu then
    item.sub_menu:show(self)
  elseif item.action then
    sfx(1)
    if item.action() then
      self:hide()
      self:close_parents()
    end
  end
end

function menu:close_parents()
  if self.parent and self.parent.active then
    self.parent:hide()
    self.parent:close_parents()
  end
end

function menu:draw()
  if not self.active then return end
  w = 44
  for _, item in pairs(self.items) do
    w = max(w, #self:get_label(item) * 4 + 14)
  end
  h = #self.items * 10 + 6
  dx = mid(1, self.x, 127 - w)
  dy = mid(1, self.y, 127 - h)

  rectfill(dx, dy, dx + w, dy + h, 0)
  rectfill(dx, dy, dx + w, dy + 1, 2)
  rect(dx, dy, dx + w, dy + h, 2)

  for i, item in ipairs(self.items) do
    lbl = self:get_label(item)
    iy = dy + 5 + (i - 1) * 10
    enabled = self:is_enabled(item)
    if i == self.sel then
      rectfill(dx + 1, iy - 1, dx + w - 1, iy + 7, 2)
      print(lbl, dx + 8, iy, enabled and 10 or 5)
      print(">", dx + 2 + sin(time() * 4) * 2, iy, 9)
    else
      print(lbl, dx + 8, iy, enabled and 13 or 5)
    end
  end

  -- draw active submenu
  item = self.items[self.sel]
  if item.sub_menu and item.sub_menu.active then
    item.sub_menu:draw()
  end
end
