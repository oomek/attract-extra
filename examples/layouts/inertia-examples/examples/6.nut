fe.load_module("inertia")

local w = flh/2
local h = flh/2 / 1.7777
local x = flw - flw/4
local y = flh/4

local img = fe.add_image( "assets/wheel.png", x, y, w, h )
img.origin = Origin.Centre
img.anchor = Anchor.Centre

///////////////////////////////////////////////////////////

img = Inertia ( img, 2000, "alpha", "rotation", "width", "height" )

// By using sufix 'all' we set all properties at once

img.tween_all = Tween.FullSine
img.loop_all = true

// Then we set properties individually

img.to_width = w * 1.2
img.to_height = h * 1.2

img.time_rotation = 1500
img.rotation = -5
img.to_rotation = 5

img.tween_alpha = Tween.Linear
img.loop_alpha = false
img.alpha = 0
img.to_alpha = 255