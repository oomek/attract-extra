///////////////////////////////////////////////////
//
// Attract-Mode Frontend - "wheel" module v0.65
//
// Provides an Animated list of artwork slots
// with fully customizable layout
//
// by Oomek - Radek Dutkiewicz 2021
//
///////////////////////////////////////////////////

// TODO:
// - morphing presets
// - slot override as a complex class object
// - load by index not by offset,
//   move idx2off to WheelSlot class
//   to allow updating text drawables in WheelSlot class
// - surface support


fe.load_module( "math.nut" )
fe.load_module( "inertia.nut" )
fe.load_module( "config.nut" )

class Wheel
{
	static VERSION = 0.65
	static PRESETS_DIR = fe.module_dir + "wheel-presets/"
	static SELECTION_SPEED = fe.get_config_value( "selection_speed_ms" ).tointeger()

	// properties
	x = null
	y = null
	alpha = null

	// locals
	cfg = null
	velocity = null
	slots = null
	queue = null
	queue_next = null
	queue_load = null
	wheel_idx = null
	slots_idx_offset = null
	slot_load_idx = null
	selection_time_old = null
	max_idx_offset = null
	first_run = null
	resync = null
	end_navigation = null
	end_navigation_idx = null

	constructor( config )
	{
		// Binding config as local
		cfg = config

		// Parsing Wheel's properties
		if ( "x" in cfg ) x = cfg.x else x = 0
		if ( "y" in cfg ) y = cfg.y else y = 0
		if ( "alpha" in cfg ) alpha = cfg.alpha else alpha = 255

		// Parsing Wheel's config
		if ( !("slots" in cfg )) cfg.slots <- 9
		if ( !("speed" in cfg )) cfg.speed <- 500
		if ( !("artwork_label" in cfg )) cfg.artwork_label <- "snap"
		if ( !("video_flags" in cfg )) cfg.video_flags <- Vid.ImagesOnly
		if ( !("zorder" in cfg )) cfg.zorder <- 0
		if ( !("zorder_offset" in cfg )) cfg.zorder_offset <- 0
		if ( !("index_offset" in cfg )) cfg.index_offset <- 0
		if ( !("preserve_aspect_ratio" in cfg )) cfg.preserve_aspect_ratio <- false
		if ( !("preset" in cfg )) cfg.preset <- ""
		fe.list.page_size = cfg.slots

		if ( !("trigger" in cfg )) cfg.trigger <- "ToNewSelection"
		if ( cfg.trigger == "ToNewSelection" )
			end_navigation = false
		else
			end_navigation = true

		// Initializing locals
		velocity = InertiaVar( 0.0, cfg.speed, 0.0 )
		slots = []
		queue = []
		queue_next = 0
		queue_load = 0
		wheel_idx = 0
		slots_idx_offset = 0
		slot_load_idx = 0
		selection_time_old = 0
		max_idx_offset = cfg.slots / 2
		resync = false
		end_navigation_idx = 0

		if ( "init" in cfg ) cfg.init()

		// Calculating zorder array based on Wheel zorder and index_offset so the selected slot is always on top
		cfg.layout.zorder <- []
		for ( local i = -max_idx_offset; i <= max_idx_offset; i++ )
			cfg.layout.zorder.push( max_idx_offset - abs( i + cfg.zorder_offset ) + cfg.zorder - 0.5 + abs( cfg.zorder_offset ))

		// Create arrays if not defined
		if ( !("x" in cfg.layout )) cfg.layout.x <- array( cfg.slots, 0 )
		if ( !("y" in cfg.layout )) cfg.layout.y <- array( cfg.slots, 0 )
		if ( !("alpha" in cfg.layout )) cfg.layout.alpha <- array( cfg.slots, 255 )

		// Setting alpha of offside slots to 0
		cfg.layout.alpha[0] = 0
		cfg.layout.alpha[cfg.slots - 1] = 0

		// Creating an array of images
		for ( local i = 0; i < cfg.slots; i++ )
		{
			local s = fe.add_image( "white.png" )
			s.video_flags = cfg.video_flags
			s.preserve_aspect_ratio = cfg.preserve_aspect_ratio
			s.mipmap = true
			slots.push( s )
		}

		// Binding callbacks
		fe.add_ticks_callback( this, "on_tick" )
		fe.add_transition_callback( this, "on_transition" )
	}
}

function Wheel::on_transition( ttype, var, ttime )
{
	if ( ttype == Transition.ToNewList )
	{
		reload_tiles()
	}
	else if ( ttype == Transition.ToNewSelection )
	{
		if ( !end_navigation )
			if ( fe.list.size > 0 )
			 	queue.push( idx2off( fe.layout.index + var, fe.layout.index ))
	}
	else if ( ttype == Transition.FromOldSelection )
	{
	}
	else if ( ttype == Transition.EndNavigation )
	{
		if ( end_navigation )
			if ( fe.list.size > 0 )
				queue.push( idx2off( fe.layout.index, end_navigation_idx ))

		end_navigation_idx = fe.layout.index
	}

	return false
}

function Wheel::on_tick( ttime )
{
	// ANIMATING THE WHEEL
	//
	if ( queue_load == 0 && queue_next == 0 ) resync = false

	if ( queue.len() > 0 )
		if ( resync == false || sign( queue[0] ) == velocity.dir )
			queue_next += queue.remove(0)

	if ( queue_next != 0 )
	{
		if ( fe.layout.time - selection_time_old > SELECTION_SPEED )
		{
			selection_time_old = fe.layout.time
			local dir = sign( queue_next )
			if ( abs( queue_next + queue_load ) > cfg.slots )
			{
				local jump = queue_next + queue_load - cfg.slots * dir
				wheel_idx = wrap( wheel_idx + jump, fe.list.size )
				queue_next -= jump
				resync = true
			}
			if ( queue_next != 0 )
			{
				velocity.from += dir
				queue_load += dir
				slots_idx_offset -= dir
				slots_idx_offset = wrap( slots_idx_offset, cfg.slots )
				queue_next -= dir
			}
		}
	}

	// Fix for delay == 0 which is still broken apparently
	if ( queue_load > 0 )
		slot_load_idx = wrap( cfg.slots - floor( velocity.get ) - slots_idx_offset - 1, cfg.slots )
	if ( queue_load < 0 )
		slot_load_idx = wrap( cfg.slots - ceil( velocity.get ) - slots_idx_offset, cfg.slots )


	// LOADING ARTWORK
	//
	if ( queue_load != 0 )
	{
		if ( velocity.get + 0.5 < queue_load && velocity.dir > 0 )
		{
			queue_load--
			wheel_idx = wrap( ++wheel_idx, fe.list.size )
			slots[slot_load_idx].file_name = fe.get_art( cfg.artwork_label,
			                                             idx2off( wheel_idx + max_idx_offset + cfg.index_offset, fe.list.index ),
			                                             0,
			                                             cfg.video_flags & 1 )
		}
		if ( velocity.get - 0.5 > queue_load && velocity.dir < 0 )
		{
			queue_load++
			wheel_idx = wrap( --wheel_idx, fe.list.size )
			slots[slot_load_idx].file_name = fe.get_art( cfg.artwork_label,
			                                             idx2off( wheel_idx - max_idx_offset + cfg.index_offset, fe.list.index ),
			                                             0,
			                                             cfg.video_flags & 1 )
		}
	}


	// SETTING PROPERTIES
	//
	// Adding 8192 to avoid negative numbers and to normalize float precision
	local mix_idx2 = floor( velocity.get + 8192.0 ) - 8192
	local mix_idx1 = mix_idx2 + 1
	local mix_amount = ( velocity.get + 8192.0 ) % sign( velocity.get )

	// Applying interpolated layout properties to slots
	foreach ( name, prop in cfg.layout )
	{
		for ( local i = 0; i < cfg.slots; i++ )
		{
			local idx1 = wrap( mix_idx1 + i + slots_idx_offset, cfg.slots )
			local idx2 = wrap( mix_idx2 + i + slots_idx_offset, cfg.slots )
			slots[i][name] = mix( prop[idx1], prop[idx2], mix_amount )
			if ( name == "x" ) slots[i][name] += x
			else if ( name == "y" ) slots[i][name] += y
			else if ( name == "alpha" ) slots[i][name] = slots[i][name] / 255.0 * alpha
			else if ( name == "origin_x" ) slots[i][name] += slots[i].width / 2
			else if ( name == "origin_y" ) slots[i][name] += slots[i].height / 2
		}
	}

	// Center slots if origin not defined in the layout
	if ( !("origin_x" in cfg.layout )) foreach ( i, s in slots ) s.origin_x = s.width / 2
	if ( !("origin_y" in cfg.layout )) foreach ( i, s in slots ) s.origin_y = s.height / 2
}

function Wheel::reload_tiles()
{
	wheel_idx = fe.list.index
	end_navigation_idx = fe.list.index
	slots_idx_offset = 0
	velocity.set = 0.0
	slot_load_idx = 0
	queue_next = 0
	queue_load = 0

	for ( local i = 0; i < cfg.slots; i++ )
		slots[i].file_name = fe.get_art( cfg.artwork_label,
		                                 i - max_idx_offset + cfg.index_offset,
		                                 0,
		                                 cfg.video_flags & 1 )
}

function Wheel::idx2off( new, old )
{
	local positive = wrap( new - old, fe.list.size )
	local negative = wrap( old - new, fe.list.size )
	if ( positive > negative )
		return -negative
	else
		return positive
}

// Binding the wheel to fe
fe.add_wheel <- Wheel
