-- input

input = {
  handlers, stack = {}, {}
}

function input:blocked()
  phase = game.fsm.current
  return phase != "select" and phase != "move" and phase != "target" and phase != "gameover" or game.transitioning
end

function input:update()
  if self:blocked() then return end
  for id = 0, 5 do
    if btnp(id) and self.handlers[id] then
      self.handlers[id]()
    end
  end
end

function input:bind(b)
  self.handlers = {}
  for k, fn in pairs(b) do
    self.handlers[k] = fn
  end
end

function input:push()
  add(self.stack, self.handlers)
  self.handlers = {}
end

function input:pop()
  if #self.stack > 0 then
    self.handlers = deli(self.stack)
  end
end

function input:clear()
  self.handlers = {}
end
