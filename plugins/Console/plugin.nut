///////////////////////////////////////////////////
//
// Attract-Mode Frontend - "Console" plugin v1.1
//
// by Oomek - Radek Dutkiewicz 2021
//
///////////////////////////////////////////////////

class UserConfig </ help="A plugin that shows the console output on the screen v1.0" />
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
	static VERSION = 1.1
	static CON_ZORDER = _intsize_ // maximum signed int so it's always sitting on top
	static PRINT = ::print
	con = null
	pass_through = null
	visible = null

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
		con.zorder = CON_ZORDER
	}

	function console_signal( sig )
	{
		if ( sig == "back" && con.visible == true )
		{
			con.visible = false
			return true
		}
	}

	function console_print( str )
	{
		local p = fe.plugin["Console"]
		p.con.visible = true
		if ( p.pass_through ) p.PRINT( str )
		p.con.msg += "> " + rstrip(str) + "\n"
		p.con.first_line_hint++
		if ( p.con.first_line_hint > 0 )
		{
			p.con.msg = rstrip( p.con.msg_wrapped ) + "\n"
			p.con.first_line_hint++
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
::print <- Console.console_print
