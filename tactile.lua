local tactile = {}

local function any(t, f)
  for i = 1, #t do
    if f(t[i]) then
      return true
    end
  end
  return false
end

local Control = {}

function Control:addAxisDetector(f)
  table.insert(self._detectors, f)
end

function Control:addPositiveButtonDetector(f)
  table.insert(self._detectors, function()
    if f() then
      return 1
    else
      return 0
    end
  end)
end

function Control:addNegativeButtonDetector(f)
  table.insert(self._detectors, function()
    if f() then
      return -1
    else
      return 0
    end
  end)
end

function Control:addButtonPair(negative, positive)
  table.insert(self._detectors, function()
    local n, p = negative(), positive()
    if n and p then
      return 0
    elseif n then
      return -1
    elseif p then
      return 1
    else
      return 0
    end
  end)
end

function Control:getValue()
  for i = #self._detectors, 1, -1 do
    local value = self._detectors[i]()
    if math.abs(value) > self.deadzone then
      return value
    end
  end
  return 0
end

function Control:isDown(dir)
  if dir then
    return (self:getValue() < 0) == (dir < 0)
  else
    return self:getValue() ~= 0
  end
end

function Control:pressed(dir)
  if self._downPrevious or not self._downCurrent then
    return false
  end
  if dir then
    return (self:getValue() < 0) == (dir < 0)
  else
    return true
  end
end

function Control:released()
  if self._downCurrent or not self._downPrevious then
    return false
  end
  if dir then
    return (self:getValue() < 0) == (dir < 0)
  else
    return true
  end
end

function Control:update()
  self._downPrevious = self._downCurrent
  self._downCurrent = self:isDown()
end

function tactile.newControl()
  local control = {
    deadzone = .5,
    _detectors = {},
    _downCurrent = false,
    _downPrevious = false,
  }

  setmetatable(control, {__index = Control})
  return control
end

return tactile
