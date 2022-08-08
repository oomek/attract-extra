fe.load_module("inertia")

local txt1 = fe.add_text( "ITEM 1", flw/2, flh/2.5 - flh/8, flw/2, flh/16 )
txt1.char_size = flh/16
txt1.set_rgb( 200, 200, 100 )

local txt2 = fe.add_text( "ITEM 2", flw/2, flh/2.5, flw/2, flh/16 )
txt2.char_size = flh/16
txt2.set_rgb( 200, 100, 200 )

local txt3 = fe.add_text( "ITEM 3", flw/2, flh/2.5 + flh/8, flw/2, flh/16 )
txt3.char_size = flh/16
txt3.set_rgb( 100, 200, 200 )

///////////////////////////////////////////////////////////

txt1 = Inertia( txt1, 1200, "x" )
txt2 = Inertia( txt2, 1200, "x" )
txt3 = Inertia( txt3, 1200, "x" )

txt1.tween_x = Tween.Back
txt2.tween_x = Tween.Back
txt3.tween_x = Tween.Back

txt2.delay_x = 100
txt3.delay_x = 200

fe.add_transition_callback( "on_transition" )
function on_transition( ttype, var, ttime )
{
    if ( ttype == Transition.ToNewSelection)
    {
        txt1.x = flw
        txt1.to_x = flw - flw/2

        txt2.x = flw
        txt2.to_x = flw - flw/2

        txt3.x = flw
        txt3.to_x = flw - flw/2
    }
}
