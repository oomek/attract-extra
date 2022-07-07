/*
################################################################################

Attract-Mode Frontend - Wheel module v1.28
Provides an animated artwork strip

by Oomek - Radek Dutkiewicz 2022
https://github.com/oomek/attract-extra

################################################################################


INITIALIZATION:
--------------------------------------------------------------------------------
local wheel = fe.add_wheel( preset )

preset can be one of the following:

> string - for example "arch-vertical"
  which is loaded from modules/wheel-presets folder

> file path - for example "my_preset.nut" that is loaded from the layout folder

> table - for example my_preset defined inside the layout code as local


PROPERTIES:
--------------------------------------------------------------------------------
x

y

alpha

speed

artwork_label

video_flags

blend_mode

zorder

zorder_offset

index_offset

preserve_aspect_ratio

trigger

...TODO


EXAMPLES:
--------------------------------------------------------------------------------
fe.load_module("wheel.nut")

local wheel = fe.add_wheel( "arch-vertical" )

...TODO

################################################################################
*/



fe.load_module( "math" )
fe.load_module( "inertia" )
fe.load_module( "config" )

class Wheel
{
	static VERSION = 1.28
	static PRESETS_DIR = ::fe.module_dir + "wheel-presets/"
	static SCRIPT_DIR = ::fe.script_dir
	static SELECTION_SPEED = ::fe.get_config_value( "selection_speed_ms" ).tointeger()
	FRAME_TIME = null

	// properties
	x = null
	y = null
	alpha = null

	// locals
	cfg = null
	preset = null
	layout = null
	surface = null
	parent = null
	anchor = null
	anim = null
	anim_int = null
	slots = null
	queue = null
	queue_next = null
	queue_load = null
	wheel_idx = null
	max_idx_offset = null
	end_idx_old = null
	end_idx_offset = null
	end_navigation = null
	selected_slot_idx = null
	selection_time_old = null
	resync = null
	sel_slot = null


	constructor( ... )
	{
		// Variable arguments parser
		local config = ""

		if ( vargv.len() == 1 )
		{
			config = vargv[0]
			parent = ::fe.layout
			surface = ::fe
		}
		else if ( vargv.len() == 2 )
		{
			config = vargv[0]
			parent = vargv[1]
			surface = vargv[1]
		}
		else
			throw "add_wheel: Wrong number of parameters\n"

		// Config / Preset Loader
		if ( typeof config == "string" )
		{
			if ( ends_with( config, ".nut" ))
				cfg = ::dofile( SCRIPT_DIR + config, true )
			else
				cfg = ::dofile( PRESETS_DIR + config + ".nut", true )

			layout = {}
			cfg.layout <- {}
			cfg.parent <- parent
			cfg.init()
		}
		else
		{
			cfg = config
			layout = {}
			cfg.layout <- {}
			cfg.init()
		}

		if ( "preset" in cfg )
		{
			preset = ::dofile( PRESETS_DIR + cfg.preset + ".nut", true )
			delete cfg.preset
			preset.layout <- {}
			preset.parent <- parent
			preset.init()
		}

		// Copying preset parameters to config
		if ( preset )
			foreach ( k, v in preset )
				if ( !( k in cfg ) && k != "layout" && typeof v != "function" )
					cfg[k] <- preset[k]

		// Parsing Wheel's properties
		if ( "x" in cfg ) x = cfg.x else x = 0
		if ( "y" in cfg ) y = cfg.y else y = 0
		if ( "alpha" in cfg ) alpha = cfg.alpha else alpha = 255

		// Parsing Wheel's config
		if ( !("slots" in cfg )) cfg.slots <- 9
		if ( !("speed" in cfg )) cfg.speed <- 500
		if ( !("anchor" in cfg )) cfg.anchor <- ::Wheel.Anchor.Centre
		if ( !("artwork_label" in cfg )) cfg.artwork_label <- "snap"
		if ( !("video_flags" in cfg )) cfg.video_flags <- Vid.Default
		if ( !("blend_mode" in cfg )) cfg.blend_mode <- BlendMode.Alpha
		if ( !("zorder" in cfg )) cfg.zorder <- 0
		if ( !("zorder_offset" in cfg )) cfg.zorder_offset <- 0
		if ( !("index_offset" in cfg )) cfg.index_offset <- 0
		if ( !("preserve_aspect_ratio" in cfg )) cfg.preserve_aspect_ratio <- false
		if ( !("trigger" in cfg )) cfg.trigger <- Transition.ToNewSelection
		if ( !("preset" in cfg )) cfg.preset <- ""

		// Copying updated config parameters back to preset
		if ( preset )
			foreach ( k, v in cfg )
				if ( k != "layout" && typeof v != "function" )
					preset[k] <- cfg[k]

		// Copying array pointers from config and preset to master layout table
		if ( preset )
		{
			foreach ( k, v in preset.layout )
			{
				if ( v.len() == 0 ) preset.layout[k] = ::array( cfg.slots, 0.0 )
				if ( !( k in layout )) layout[k] <- []
				layout[k] = preset.layout[k]
			}
		}

		foreach ( k, v in cfg.layout )
		{
			if ( v.len() == 0 ) cfg.layout[k] = ::array( cfg.slots, 0.0 )
			if ( !( k in layout )) layout[k] <- []
			layout[k] = cfg.layout[k]
		}

		// First update
		if ( "update" in preset ) preset.update()
		if ( "update" in cfg ) cfg.update()

		// Initializing locals
		anim = ::Inertia( 0.0, cfg.speed, 0.0 )
		anim.mass = 1.0
		anim_int = 0
		slots = []
		queue = []
		queue_next = 0
		queue_load = 0
		wheel_idx = 0
		max_idx_offset = cfg.slots / 2
		end_idx_old = 0
		end_idx_offset = 0
		end_navigation = true
		selected_slot_idx = max_idx_offset - cfg.index_offset
		selection_time_old = 0
		resync = false
		FRAME_TIME = 1000 / ScreenRefreshRate

		// Create alpha array if not defined
		if ( !("alpha" in layout )) layout.alpha <- ::array( cfg.slots, 255 )

		// Setting alpha of offside slots to 0
		layout.alpha[0] = 0
		layout.alpha[cfg.slots - 1] = 0

		// Creating an array of images
		for ( local i = 0; i < cfg.slots; i++ )
		{
			local s = surface.add_image( "", 0, 0, 1, 1 )
			s.video_flags = cfg.video_flags
			s.preserve_aspect_ratio = cfg.preserve_aspect_ratio
			s.mipmap = true
			s.blend_mode = cfg.blend_mode
			s.zorder =  max_idx_offset - ::abs( i + cfg.zorder_offset - max_idx_offset ) + cfg.zorder + ::abs( cfg.zorder_offset )
			slots.push( s )
		}

		// To be accessed by the layout
		sel_slot = slots[selected_slot_idx]
		cfg.images <- []
		cfg.images = slots

		// Binding callbacks
		::fe.add_ticks_callback( this, "on_tick" )
		::fe.add_transition_callback( this, "on_transition" )
	}
}

function Wheel::on_transition( ttype, var, ttime )
{
	if ( ttype == Transition.ToNewList )
	{
		reload_slots()
	}

	else if ( ttype == Transition.ToNewSelection )
	{
		if ( ::fe.list.size > 0 )
		{
			if ( cfg.trigger == ttype )
			{
				foreach ( s in slots ) s.video_flags = cfg.video_flags | Vid.NoAudio

				if ( ::abs( var ) == 1 )
					queue.push( var )
				else
					queue.push( idx2off( ::fe.layout.index + var, ::fe.layout.index ))
				end_navigation = false
			}
			else end_idx_offset += var
		}
	}

	else if ( ttype == Transition.FromOldSelection )
	{
	}

	else if ( ttype == Transition.EndNavigation )
	{
		if ( ::fe.list.size > 0 )
		{
			if ( cfg.trigger == ttype )
			{
				foreach ( s in slots ) s.video_flags = cfg.video_flags | Vid.NoAudio

				if ( ::abs( end_idx_offset ) == 1 )
					queue.push( end_idx_offset )
				else
					queue.push( idx2off( end_idx_old + end_idx_offset, end_idx_old ) )
			}

			end_idx_old = ::fe.layout.index
			end_idx_offset = 0
			end_navigation = true
		}
	}

	return false
}

function Wheel::on_tick( ttime )
{
	// ANIMATING THE WHEEL
	if ( queue_load == 0 && queue_next == 0 ) resync = false

	if ( queue.len() > 0 )
		if ( resync == false || (( ::sign( queue[0] ) == ::sign( -anim.velocity ) ) && ( ::sign( queue[0] ) == ::sign( queue_next ) || ( queue_next == 0 ))))
			queue_next += queue.remove(0)

	if ( queue_next != 0 )
	{
		if ( ::fe.layout.time - selection_time_old > SELECTION_SPEED )
		{
			selection_time_old = ::fe.layout.time
			local dir = ::sign( queue_next )
			if ( ::abs( queue_next + queue_load ) > cfg.slots )
			{
				local jump = queue_next + queue_load - cfg.slots * dir
				wheel_idx = ::wrap( wheel_idx + jump, ::fe.list.size )
				queue_next -= jump
				resync = true
			}
			if ( queue_next != 0 )
			{
				anim.from += dir
				anim_int -= dir
				queue_load += dir
				queue_next -= dir
			}
		}
	}

	// Handling audio flags
	if ( end_navigation == true && wheel_idx == ::fe.layout.index && queue_load == 0 )
	{
		slots[selected_slot_idx].video_flags = cfg.video_flags
		end_navigation = false
	}

	// LOADING ARTWORK
	if ( anim.get + anim_int <= -0.5 && ( anim.velocity < 0.0 || cfg.speed < FRAME_TIME ))
	{
		swap_slots( 1 )
		anim_int++
		queue_load--
		wheel_idx++
		wheel_idx = ::wrap( wheel_idx, ::fe.list.size )
		slots[cfg.slots - 1].video_flags = cfg.video_flags | Vid.NoAudio
		slots[cfg.slots - 1].file_name = ::fe.get_art( cfg.artwork_label,
		                                             idx2off( wheel_idx + max_idx_offset + cfg.index_offset, ::fe.list.index ),
		                                             0,
		                                             cfg.video_flags & Art.ImagesOnly )
	}
	if ( anim.get + anim_int >= 0.5 && ( anim.velocity > 0.0 || cfg.speed < FRAME_TIME ))
	{
		swap_slots( -1 )
		anim_int--
		queue_load++
		wheel_idx--
		wheel_idx = ::wrap( wheel_idx, ::fe.list.size )
		slots[0].video_flags = cfg.video_flags | Vid.NoAudio
		slots[0].file_name = ::fe.get_art( cfg.artwork_label,
		                                             idx2off( wheel_idx - max_idx_offset + cfg.index_offset, ::fe.list.index ),
		                                             0,
		                                             cfg.video_flags & Art.ImagesOnly )
	}

	// SETTING PROPERTIES
	local mix_amount = anim.get % 1.0
	if ( anim.get <= 0 ) mix_amount += 1
	local mix_idx2 = ::floor( 0.5 - mix_amount )
	local mix_idx1 = mix_idx2 + 1

	// Applying interpolated layout properties to slots
	foreach ( name, prop in layout )
	{
		for ( local i = 0; i < cfg.slots; i++ )
		{
			local idx1 = ::wrap( mix_idx1 + i, cfg.slots )
			local idx2 = ::wrap( mix_idx2 + i, cfg.slots )
			slots[i][name] = ::mix( prop[idx1], prop[idx2], mix_amount )

			if ( name == "x" ) slots[i][name] += x
			else if ( name == "y" ) slots[i][name] += y
			else if ( name == "alpha" ) slots[i][name] = slots[i][name] / 255.0 * alpha
			else if ( name == "origin_x" ) slots[i][name] += slots[i].width * cfg.anchor[0]
			else if ( name == "origin_y" ) slots[i][name] += slots[i].height * cfg.anchor[1]
		}
	}

	// sel_slot.alpha = 255

	// Center slots if origin not defined in layout
	foreach ( i, s in slots )
	{
		if ( !( "x" in layout )) s.x = x
		if ( !( "y" in layout )) s.y = y
		if ( !( "origin_x" in layout )) s.origin_x = s.width * cfg.anchor[0]
		if ( !( "origin_y" in layout )) s.origin_y = s.height * cfg.anchor[1]
	}

	for ( local i = 0; i < cfg.slots; i++ ) slots[i].visible = slots[i].alpha
}

function Wheel::_get( idx )
{
	switch ( idx )
	{
		case "x":
		case "y":
		case "alpha":
			return idx

		case "spinning":
			return anim.get != 0

		default:
			if ( idx in this ) return idx
			else if ( idx in preset ) return preset[idx]
			else if ( idx in cfg ) return cfg[idx]
	}
}

function Wheel::_set( idx, val )
{
	switch ( idx )
	{
		case "x":
		case "y":
		case "alpha":
			idx = val
			break

		case "speed":
			cfg.speed = val
			anim.time = val
			break

		case "preserve_aspect_ratio":
			foreach( s in slots ) s[idx] = val
			break

		case "zorder":
			cfg.zorder = val
			foreach( i, s in slots )
				s.zorder =  max_idx_offset - ::abs( i + cfg.zorder_offset - max_idx_offset ) + cfg.zorder + ::abs( cfg.zorder_offset )
			break

		default:
			if ( idx in this ) idx = val
			else if ( idx in preset ) preset[idx] = val
			else if ( idx in cfg ) cfg[idx] = val
			if ( "update" in preset ) preset.update()
			if ( "update" in cfg ) cfg.update()
	}
}

Wheel.Anchor <-
{
	Centre = [0.5,0.5]
	Left = [0.0,0.5]
	Right = [1.0,0.5]
	Top = [0.5,0.0]
	Bottom = [0.5,1.0]
	TopLeft = [0.0,0.0]
	TopRight = [1.0,0.0]
	BottomLeft = [0.0,1.0]
	BottomRight = [1.0,1.0]
}

function Wheel::reload_slots()
{
	::fe.list.page_size = ::min( cfg.slots, ::max( ::fe.list.size / 2, 1 ))
	wheel_idx = ::fe.list.index
	end_idx_old = ::fe.list.index
	end_idx_offset = 0
	anim_int = 0
	anim.set = 0.0
	queue_next = 0
	queue_load = 0

	for ( local i = 0; i < cfg.slots; i++ )
	{
		slots[i].file_name = ::fe.get_art( cfg.artwork_label,
		                                 i - max_idx_offset + cfg.index_offset,
		                                 0,
		                                 cfg.video_flags & Art.ImagesOnly )

		slots[i].video_flags = cfg.video_flags | Vid.NoAudio
	}

	slots[selected_slot_idx].video_flags = cfg.video_flags
}

function Wheel::idx2off( new, old )
{
	local positive = ::wrap( new - old, ::fe.list.size )
	local negative = ::wrap( old - new, ::fe.list.size )
	if ( positive > negative )
		return -negative
	else
		return positive
}

function Wheel::swap_slots( dir )
{
	if ( dir == 1 )
		for ( local i = 1; i < cfg.slots; i++ ) slots[i].swap( slots[i - 1] )
	else
		for ( local i = cfg.slots - 1; i > 0; i-- ) slots[i].swap( slots[i - 1] )
}

function Wheel::ends_with( name, string )
{
	if ( name.slice( name.len() - string.len(), name.len()) == string )
		return true
	else
		return false
}

// Binding the wheel to fe
fe.add_wheel <- Wheel
