-- state machine

state = {}

function state:new(states, initial)
  fsm = {
    states = states,
    current = nil,
    prev = nil
  }
  setmetatable(fsm, {__index = self})
  if initial then fsm:switch(initial) end
  return fsm
end

function state:switch(name)
  if self.current then
    st = self.states[self.current]
    if st.exit then st:exit() end
  end

  self.prev = self.current
  self.current = name

  st = self.states[name]

  if st.bindings then
    if self.prev and self.states[self.prev].bindings then
      input:pop()
    end
    input:push()
    input:bind(st.bindings)
  elseif self.prev and self.states[self.prev].bindings then
    input:pop()
  end

  if st.init then st:init() end
end

function state:update()
  st = self.states[self.current]
  if st.update then st:update() end
end

function state:draw()
  st = self.states[self.current]
  if st.draw then st:draw() end
end
