fe.load_module("inertia")

local w = flh/2
local h = flh/2 / 1.7777
local x = flw - flw/4
local y = flh/2

local img = fe.add_image( "assets/wheel.png", x, y, w, h )
img.origin = Origin.Centre
img.anchor = Anchor.Centre

///////////////////////////////////////////////////////////

img = Inertia ( img, 500, "y", "origin_y" )

// Setting y

img.tween_y = Tween.Cubic
img.y = flh * 1.5
img.to_y = flh/2

// Setting origin_y

img.tween_origin_y = Tween.Bounce
img.time_origin_y = 100
img.tail_origin_y = 400
img.delay_origin_y = img.time_y
img.origin_y = flh/5
img.to_origin_y = 0

