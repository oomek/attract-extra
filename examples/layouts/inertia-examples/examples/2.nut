fe.load_module("inertia")

local txt = fe.add_text( "RAINBOW TEXT", flw/2, 0, flw/2, flh )
txt.char_size = flh/16

///////////////////////////////////////////////////////////

txt = Inertia( txt, 1500, "red", "green", "blue" )
txt.tween_all = Tween.FullSine
txt.loop_all = true
txt.set_all = 150
txt.to_all = 255

// Negative delay starts tween from a given offset in ms.
// In this case to make sines for each colour not overlapping.

txt.delay_green = -500 // phase offset 33%
txt.delay_blue = -1000 // phase offset 66%