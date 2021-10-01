fe.load_module("inertia")

local txt = fe.add_text( "RAINBOW TEXT", flw/2, 0, flw/2, flh )
txt.char_size = flh/16



txt = Inertia( txt, 1500, "red", "green", "blue" )
txt.tween = Tween.FullSine
txt.loop = true
txt.to = 150

txt.delay_green = -500 // phase offset 33%
txt.delay_blue = -1000 // phase offset 66%