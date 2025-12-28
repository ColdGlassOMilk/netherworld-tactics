-- utils
function obj(t)
  return setmetatable(t, {__index=_ENV})
end
