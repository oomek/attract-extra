///////////////////////////////////////////////////
//
// Attract-Mode Frontend - "config" module v1.0
//
// Provides the ability to read a value
// defined in attract.cfg
//
// usage example:
// local ms = fe.get_config_value( "selection_speed_ms" )
//
// by Oomek - Radek Dutkiewicz 2021
//
///////////////////////////////////////////////////

if ( !( "AttractConfig" in getroottable() ))
{
	AttractConfig <-
	{
		init = function()
		{
			local file = file( fe.path_expand( FeConfigDirectory + "attract.cfg") , "r" )
			blob = file.readblob( file.len() )
		},

		get_config_value = function( str )
		{
			local str_index = 0
			while ( !blob.eos() && str_index < str.len() )
			{
				if ( blob.readn('b') == str[str_index] )
					str_index++
				else
					str_index = 0
			}
			local value = ""
			local char = ""
			while ( !blob.eos() )
			{
				char = blob.readn('b').tochar()
				if ( char == "\n" ) break
				value += char
			}
			return strip( value )
		},
	}

	AttractConfig.init()
	fe.get_config_value <- AttractConfig.get_config_value
}
