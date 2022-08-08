fe.load_module("inertia")

local w = flh/2
local h = flh/2 / 1.7777
local x = flw - flw/4
local y = flh/4

local img = fe.add_image( "assets/wheel.png", x, y, w, h )
img.origin = Origin.Centre
img.anchor = Anchor.Centre

///////////////////////////////////////////////////////////

img = Inertia ( img, 500, "x", "skew_x" )

// By using sufix 'all' we set all properties at once

img.tween_all = Tween.Elastic
img.tail_all = 1500

// Then we set properties individually

img.delay_skew_x = 100
img.skew_x = -w
img.to_skew_x = 0

img.x = flw + w
img.to_x = x
