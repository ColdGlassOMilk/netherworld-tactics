-- tween system

tween = {
  active = {}
}

tween.ease = {
  linear = function(t) return t end,
  out_quad = function(t) return 1 - (1 - t) * (1 - t) end,
  out_back = function(t)
    local c = 2.70158
    return 1 + c * (t - 1) ^ 3 + (c - 1) * (t - 1) ^ 2
  end,
  in_out_quad = function(t)
    return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
  end
}

function tween:new(target, props, duration, opts)
  opts = opts or {}
  local t = {
    target = target,
    props = {},
    duration = duration,
    elapsed = 0,
    delay = opts.delay or 0,
    ease = opts.ease or tween.ease.out_quad,
    on_complete = opts.on_complete
  }
  for k, v in pairs(props) do
    t.props[k] = {start = target[k], finish = v}
  end
  add(self.active, t)
  return t
end

function tween:update()
  for t in all(self.active) do
    if t.delay > 0 then
      t.delay -= 1
    else
      t.elapsed += 1
      local p = min(t.elapsed / t.duration, 1)
      local e = t.ease(p)
      for k, v in pairs(t.props) do
        t.target[k] = v.start + (v.finish - v.start) * e
      end
      if p >= 1 then
        if t.on_complete then t.on_complete() end
        del(self.active, t)
      end
    end
  end
end

function tween:cancel_all(target)
  for t in all(self.active) do
    if t.target == target then del(self.active, t) end
  end
end

function tween:clear()
  self.active = {}
end
