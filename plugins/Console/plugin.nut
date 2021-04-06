///////////////////////////////////////////////////
//
// Attract-Mode Frontend - "Console" plugin v1.3
//
// by Oomek - Radek Dutkiewicz 2021
//
///////////////////////////////////////////////////

class UserConfig </ help="A plugin that shows the console output on the screen v1.3" />
{
	</ label="Font Size",
		help="Sets the font size",
		options="Very Small,Small,Medium,Large,Extra Large",
		order=1 />
	font_size="Medium"

	</ label="Window Opacity",
		help="Sets the opacity of the background window",
		options="0,10,20,30,40,50,60,70,80,90,100",
		order=2 />
	opacity="80"

	</ label="Pass-through",
		help="When set to Yes messages are on the screen and also in the console window",
		options="Yes,No",
		order=2 />
	pass_through="No"
}

class Console
{
	static VERSION = 1.3
	static CON_ZORDER = 2147483647 // maximum zorder value
	static PRINT = ::print
	con = null
	pass_through = null
	visible = null
	con_time_old = null
	con_event = null

	constructor()
	{
		local config = fe.get_config()
		if ( config["pass_through"].tolower() == "yes" ) pass_through = true
		else pass_through = false

		con = fe.add_text( "", 0, fe.layout.height / 2, fe.layout.width, fe.layout.height / 2 )
		con.font = "RobotoMono-Regular.ttf"
		con.alpha = 200
		con.bg_alpha = config["opacity"].tointeger() * 255 / 100
		con.word_wrap = true
		con.align = Align.TopLeft
		con.visible = false
		con_time_old = -2000
		con_event = false

		switch ( config["font_size"].tolower() )
		{
			case "very small":
				con.char_size = 12
				break
			case "small":
				con.char_size = 16
				break
			case "medium":
				con.char_size = 20
				break
			case "large":
				con.char_size = 24
				break
			case "extra large":
				con.char_size = 28
				break
			default:
				break
		}

		con.margin = con.glyph_size
		con.height += con.char_size

		fe.add_ticks_callback( this, "console_tick" )
		fe.add_signal_handler( this, "console_signal" )
	}

	function console_tick( ttime )
	{
		if ( con_event && fe.layout.time - con_time_old > 1000 )
		{
			con.zorder = CON_ZORDER
			con.visible = true
			con_event = false
		}
	}

	function console_signal( sig )
	{
		if ( sig == "back" && con.visible )
		{
			con.zorder = 0
			con_time_old = fe.layout.time
			con.visible = false
			return true
		}
	}

	function console_print( str )
	{
		con_event = true
		if ( pass_through ) PRINT( str )
		con.msg += "> " + rstrip( str.tostring() ) + "\n"
		con.first_line_hint++
		if ( con.first_line_hint > 0 )
		{
			con.msg = rstrip( con.msg_wrapped ) + "\n"
			con.first_line_hint++
		}
	}
}

function console_error_handler( message )
{
    local stack = getstackinfos(2)
    fe.plugin["Console"].console_print( "[" + stack.src + ":" + stack.line + "]:\n> " + "(ERROR) " + message )
}

seterrorhandler(console_error_handler)

fe.plugin["Console"] <- Console()
::print <- Console.console_print.bindenv( fe.plugin["Console"] )
