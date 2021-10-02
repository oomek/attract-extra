// Simplified ReadTextFile from file.nut without whitespace stripping
class ReadTextFile
{
	constructor( path )
	{
		try
		{
			_file = file( path, "r" );
			_blob = _file.readblob( 4096 );
		}
		catch ( e )
		{
			print( "Error opening file for reading: "
				+ path + ": " + e + "\n" );
		}
	}

	function read_line()
	{
		local line="";
		local char;

		while ( !eos() )
		{
			if ( _blob.eos() && _file && !_file.eos() )
				_blob = _file.readblob( 4096 );

			while ( !_blob.eos() )
			{
				char = _blob.readn( 'b' );
				if ( char == '\n' )
					return rstrip( line );

				line += char.tochar();
			}
		}

		return line;
	}

	function eos()
	{
		if ( !_blob )
			return true;
		else if ( !_file )
			return ( _blob.eos() );

		return ( _blob.eos() && _file.eos() );
	}

	_file=null;
	_blob=null;
};

function ReadFile( filename )
{
	local lines = [];
	local f = ReadTextFile( filename );
	local pos = 0;
	while ( !f.eos() )
		lines.push(f.read_line());
	return lines;
}



local EXAMPLES_COUNT = zip_get_dir( fe.script_dir + "examples/" ).len()

if ( fe.nv.rawin( "inertia-examples" ))
{
	current <- fe.nv["inertia-examples"]
}
else
{
	current <- 1
	fe.nv["inertia-examples"] <- current
}

flw <- fe.layout.width
flh <- fe.layout.height

local margin = flh / 16
local bg = fe.add_image( "assets/background.png", 0, 0, flw, flh )

local code = fe.add_text( "", margin, margin, flw/2 - margin, flh - margin*4 )
code.font = "RobotoMono-Regular.ttf"
code.word_wrap = true
code.set_bg_rgb( 20, 20, 20 )
code.bg_alpha = 200
code.char_size = flh/80
code.align = Align.TopLeft

local legend = fe.add_text( "", margin, code.height + margin, flw - margin*2, flh - code.height - margin )
legend.char_size = flh/32
legend.align = Align.MiddleCentre
legend.set_rgb( 20, 20, 20 )
legend.msg = "Up/Down - move        Left/Right - previous/next example"

local filenum = fe.add_text( "", margin, margin - flh/32, flw - margin, flh/32)
filenum.char_size = flh/40
filenum.align = Align.TopLeft
filenum.set_rgb( 20, 20, 20 )
filenum.msg = "Example: " + current + "/" + EXAMPLES_COUNT
filenum.margin = 0


local textfile = ReadFile( fe.script_dir + "examples/" + current + ".nut" )

foreach( line in textfile ) code.msg += line + "\n"

fe.do_nut(  fe.script_dir + "examples/" + current + ".nut" )


fe.add_signal_handler( "on_signal" )
function on_signal( sig )
{
	switch( sig )
	{
		case "up":
			fe.signal( "prev_game" )
			return true

		case "down":
			fe.signal( "next_game" )
			return true

		case "left":
			current --
			if ( current < 1 ) current += EXAMPLES_COUNT
			fe.nv["inertia-examples"] <- current
			fe.signal( "reload" )
			return true

		case "right":
			current ++
			if ( current > EXAMPLES_COUNT ) current -= EXAMPLES_COUNT
			fe.nv["inertia-examples"] <- current
			fe.signal( "reload" )
			return true

		default:
			return false
	}
}
