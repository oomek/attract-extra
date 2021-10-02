fe.load_module("inertia")

local w = flh/2
local h = flh/2 / 1.7777
local x = flw - flw/4
local y = -h

local img = fe.add_image( "assets/wheel.png", x, y, w, h )
img.origin = Origin.Centre
img.anchor = Anchor.Centre

///////////////////////////////////////////////////////////

img = Inertia ( img, 500, "y", "width", "height" )

// By just using a prefix we set all properties at once

img.tween = Tween.Elastic
img.loop = false
img.tail = 1500

// Now we set properties individually

img.width = w / 2.0
img.to_width = w

img.height = h * 2.0
img.to_height = h

img.to_y = flh/4
