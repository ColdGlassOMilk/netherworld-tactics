-- menu system

menu = {}
menu.__index = menu

function menu:new(items, opts)
  opts = opts or {}
  local m = {
    items = items or {},
    sel = 1,
    active = false,
    x = opts.x or 80,
    y = opts.y or 20
  }
  return setmetatable(m, self)
end

function menu:show()
  self.active = true
  self.sel = 1
end

function menu:hide()
  self.active = false
end

function menu:nav(dir)
  self.sel = ((self.sel - 1 + dir) % #self.items) + 1
  sfx(0)
end

function menu:select()
  local item = self.items[self.sel]
  if item.enabled and not item.enabled() then return end
  if item.action then
    sfx(1)
    item.action()
  end
end

function menu:draw()
  if not self.active then return end
  local w = 44
  for _, item in pairs(self.items) do
    local lbl = type(item.label) == "function" and item.label() or item.label
    w = max(w, #lbl * 4 + 14)
  end
  local h = #self.items * 10 + 6

  -- clamp to screen
  local dx = mid(1, self.x, 127 - w)
  local dy = mid(1, self.y, 127 - h)

  -- background with border
  rectfill(dx, dy, dx + w, dy + h, 0)
  rectfill(dx, dy, dx + w, dy + 1, 2)  -- top accent
  rect(dx, dy, dx + w, dy + h, 2)

  for i, item in ipairs(self.items) do
    local lbl = type(item.label) == "function" and item.label() or item.label
    local iy = dy + 5 + (i - 1) * 10
    local enabled = not item.enabled or item.enabled()

    if i == self.sel then
      -- selection highlight bar
      rectfill(dx + 1, iy - 1, dx + w - 1, iy + 7, 2)
      local col = enabled and 10 or 5  -- yellow when selected
      print(lbl, dx + 8, iy, col)
      -- animated cursor
      local cx = dx + 2 + sin(time() * 4) * 2
      print(">", cx, iy, 9)
    else
      local col = enabled and 13 or 5  -- lavender / gray
      print(lbl, dx + 8, iy, col)
    end
  end
end
