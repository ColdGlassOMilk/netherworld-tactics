-- main

function _init()
  game:init()
end

function _update()
  input:update()
  tween:update()
  game:update()
end

function _draw()
  game:draw()
end
