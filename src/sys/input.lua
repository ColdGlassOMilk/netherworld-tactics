-- input

input = {
  button = {
    left=0, right=1, up=2, down=3, o=4, x=5
  },
  handlers = {},
  hold_handlers = {},
  hold_time = {},
  hold_delay = 20 -- frames before hold triggers
}

function input:update()
  for id=0,5 do
    if btnp(id) and self.handlers[id] then
      self.handlers[id]()
    end
    -- hold detection
    if btn(id) then
      self.hold_time[id] = (self.hold_time[id] or 0) + 1
      if self.hold_time[id] == self.hold_delay and self.hold_handlers[id] then
        self.hold_handlers[id]()
      end
    else
      self.hold_time[id] = 0
    end
  end
end

function input:bind(bindings)
  self.handlers = {}
  self.hold_handlers = {}
  for key, fn in pairs(bindings) do
    if type(key) == "string" and sub(key, 1, 5) == "hold_" then
      local id = tonum(sub(key, 6))
      self.hold_handlers[id] = fn
    else
      self.handlers[key] = fn
    end
  end
end

function input:clear()
  self.handlers = {}
  self.hold_handlers = {}
end
