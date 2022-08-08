fe.load_module("inertia")

local size = flh/2
local x = flw - flw/4
local y = -size/2

local img = fe.add_image( "assets/wheel.png", x, y, size, size )
img.preserve_aspect_ratio = true
img.origin = Origin.Centre
img.anchor = Anchor.Centre

///////////////////////////////////////////////////////////

img = Inertia ( img, 2000, "y", "width", "height" )

// By using sufix 'all' we set all properties at once

img.tween_all = Tween.FullSine
img.delay_all = 500 + 1500
img.loop_all = true

// Then we set properties individually

img.to_width = size * 1.2

img.to_height = size * 1.2

img.tween_y = Tween.Bounce
img.time_y = 500
img.tail_y = 1500
img.delay_y = 0
img.loop_y = false
img.to_y = flh/4
