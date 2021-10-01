fe.load_module("inertia")

local x = flw - flw/3.5
local y = flh/2
local size = flh/8

local img1 = fe.add_image( "pixel.png", x - size*1.5, y, size, size )
img1.set_rgb( 200, 200, 100 )

local img2 = fe.add_image( "pixel.png", x, y, size, size )
img2.set_rgb( 200, 100, 200 )

local img3 = fe.add_image( "pixel.png", x + size*1.5, y, size, size )
img3.set_rgb( 100, 200, 200 )



img1 = Inertia( img1, 1000, "y" )
img2 = Inertia( img2, 1000, "y" )
img3 = Inertia( img3, 1000, "y" )

img1.mass = 1.0
img2.mass = 0.5
img3.mass = 0.0

fe.add_transition_callback( "on_transition" )
function on_transition( ttype, var, ttime )
{
    if ( ttype == Transition.ToNewSelection)
    {
        img1.to_y += var * 200
        img2.to_y += var * 200
        img3.to_y += var * 200
    }
}