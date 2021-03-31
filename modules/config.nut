///////////////////////////////////////////////////
//
// Attract-Mode Frontend - "config" module v1.1
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
		cache = {},
		blob_file = blob(),
		init = function()
		{
			local file = file( fe.path_expand( FeConfigDirectory + "attract.cfg") , "r" )
			AttractConfig.blob_file = file.readblob( file.len() )
		},

		get_config_value = function( str )
		{
			if ( str in AttractConfig.cache )
				return AttractConfig.cache[str]

			local str_index = 0
			while ( !AttractConfig.blob_file.eos() && str_index < str.len() )
			{
				if ( AttractConfig.blob_file.readn('b') == str[str_index] )
					str_index++
				else
					str_index = 0
			}
			local value = ""
			local char = ""
			while ( !AttractConfig.blob_file.eos() )
			{
				char = AttractConfig.blob_file.readn('b').tochar()
				if ( char == "\n" ) break
				value += char
			}

			AttractConfig.cache[str] <- strip( value )
			return AttractConfig.cache[str]
		},
	}

	AttractConfig.init()
	fe.get_config_value <- AttractConfig.get_config_value
}
