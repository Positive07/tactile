Tactile
=======

Tactile is an input library for LÖVE that bridges the gap between different input methods and types. In Tactile, there is no distinction between buttons and analog controls - controls are both buttons and axes at the same time.

```lua
Control = {
  Horizontal = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'leftx'))
    :addButtonPair(tactile.keys('a', 'left'), tactile.keys('d', 'right')),
  Vertical = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'lefty'))
    :addButtonPair(tactile.keys('w', 'up'), tactile.keys('s', 'down')),
  Fire = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'triggerleft'))
    :addAxis(tactile.gamepadAxis(1, 'triggerright'))
    :addButton(tactile.gamepadButtons(1, 'a'))
    :addButton(tactile.keys 'x')
}

function love.update(dt)
  -- movement - using axis inputs
  local inputVector = vector(Control.Horizontal(), Control.Vertical())
  player.pos = player.pos + player.speed * inputVector * dt

  -- firing - using button inputs
  if Control.Fire:isDown() then
    player:shoot()
  end
end
```

Overview
--------
Tactile has two types of objects:
- **Controls**: A control represents a distinct action in the game. For example, you might make "horizontal" and "vertical" controls for movement using the arrow keys or analog stick, and "primary" and "secondary" controls for the A and B button.
- **Detectors**: A detector is a function that checks for a certain kind of input. These are split up into three types:
  - **Axis detectors**: An axis detector checks for an analog input. For example, a function that returned the value of a `GamepadAxis` would be an axis detector.
  - **Button detectors**: A button detector checks the state of a single button.
  - **Button pair detectors**: A button pair detector uses two buttons to represent an axis. One button represents the negative end of an axis, and the other represents the positive end.

### Controls
Controls contain a series of detectors and use them to act as both a button and an axis. The most important function is `Control:getValue`, which runs through all of the detectors in order and uses them to calculate a value between -1 and 1.
- If the detector is an axis detector, the resulting value will be whatever number the axis detector returns.
- If the detector is a button detector, the resulting value will be 0 if the button detector returns `false` and 1 if the button detector returns `true`.
- If the detector is a button pair detector...
  - If both or neither the negative and positive detectors return `true`, the resulting value will be 0.
  - If only the negative detector returns `true`, the resulting value will be -1.
  - If only the positive detector returns `true`, the resulting value will be 1.
- Each detector will override the values of the previous one as long as they are non-zero (i.e., their absolute value is greater than the deadzone)

Controls also act as buttons, so they can be "down" or not "down". They're considered to be "down" if `Control:getValue` is a non-zero number. Furthermore, controls can be "down" in a certain direction, meaning `Control:getValue` is less than `-deadzone` or greater than `deadzone`. They also keep track of whether they were pressed or released in the current frame.

### Examples
That was all very abstract. What does this mean? Well, here are some examples of common ways to use Tactile. For these examples, let's assume that we've set up the controls like this:

```lua
Control = {
  Horizontal = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'leftx'))
    :addButtonPair(tactile.keys('a', 'left'), tactile.keys('d', 'right')),
  Vertical = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'lefty'))
    :addButtonPair(tactile.keys('w', 'up'), tactile.keys('s', 'down')),
  Fire = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'triggerleft'))
    :addAxis(tactile.gamepadAxis(1, 'triggerright'))
    :addButton(tactile.gamepadButtons(1, 'a'))
    :addButton(tactile.keys 'x')
}
```

First, let's think about movement. This is the perfect time to use controls like axes. The `Horizontal` and `Vertical` controls have the left analog stick, arrow keys, and WASD mapped to them, so you can easily do something like this:

```lua
player.x = player.x + Control.Horizontal:getValue() * player.speed * dt
player.y = player.y + Control.Vertical:getValue() * player.speed * dt
```

Since `Contol:getValue()` always returns a number between -1 and 1, the player will move at a speed and in a direction that makes sense given the input.

Now let's think about shooting. This is something that's handled by a button input. We'll use the `Fire` control:

```lua
if Control.Fire:isDown() then
  player:shoot()
end
```

That's all we have to do! The `Fire` control has the `X` key, `A` button on the gamepad, and left and right triggers mapped to it. If `X` or `A` are pushed down, or if either trigger is pushed down more than halfway, the `Control.Fire` will register as being pushed down.

One more example: menu controls. This is the sneaky one! It's obvious to use `Horizontal` and `Vertical` as axes and `Fire` as a button, but for menus, we need to use the analog stick and the arrow keys as button presses to move a cursor around. But since controls are both axes and buttons, this is already set up for us. We'll use the `dir` argument of `Control:pressed` to detect button presses in certain directions.

```lua
if Control.Horizontal:pressed(-1) then
  // move the cursor to the left
end
if Control.Horizontal:pressed(1) then
  // move the cursor to the right
end
if Control.Vertical:pressed(-1) then
  // move the cursor up
end
if Control.Vertical:pressed(1) then
  // move the cursor down
end
```

Installation
------------
Place tactile.lua somewhere in your project. To use it, do:
```lua
local tactile = require 'path.to.tactile'
```

API
---
### `Control = tactile.newControl()`
Creates and returns a new control.

### `Control:addAxis(f)`
Adds an axis detector to the control.
- `f` (function) - an axis detector. Axis detectors are functions that return a number between -1 and 1.

### `Control:addButton(f)`
Adds a button detector to the control.
- `f` (function) - a button detector. Button detectors are functions that return a boolean value.

### `Control:addButtonPair(negative, positive)`
Adds a pair of button detectors to the control. The negative button detector will be mapped to -1, and the positive button detector will be mapped to 1.
- `negative` (function) - the negative button detector.
- `positive` (function) - the positive button detector.

### `Control:getValue()`
Returns the current axis value of the control. The control checks each axis and button detector in the order they were added. Any detector that has a non-zero value will overwrite the previous one, so the detector that should have the highest precedence should be added last. Button detectors are mapped to 1, and button pairs are mapped to -1 and 1.

### ```Control:isDown(dir)```
Returns whether the control is down or not. The control is considered to be down if its absolute value is greater than the deadzone.
- `dir` (optional) - set this to -1 or 1 to check if the control is down in a certain direction. For example, if the control has a button pair detector where the negative button is the left arrow key and the positive button is the right arrow key, `Control:isDown(-1)` will only return true if the left arrow key is down.

### ```Control:pressed(dir)```
Returns whether the control was pressed this frame.
- `dir` (optional) - the direction to check.

### ```Control:released(dir)```
Returns whether the control was released this frame.
- `dir` (optional) - the direction to check.

### ```Control:upate()```
Updates the state of the control. Call this on all of your controls each frame. Sorry you have to do this. :(
