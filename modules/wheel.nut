///////////////////////////////////////////////////
//
// Attract-Mode Frontend - "wheel" module v1.0
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
	static VERSION = 1.0
	static PRESETS_DIR = fe.module_dir + "wheel-presets/"
	static SELECTION_SPEED = fe.get_config_value( "selection_speed_ms" ).tointeger()
	FRAME_TIME = null

	// properties
	x = null
	y = null
	alpha = null

	// locals
	cfg = null
	velocity = null
	velocity_int = null
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
	mix_idx_off = null
	sel_slot = null


	constructor( config )
	{
		FRAME_TIME = 1000 / ScreenRefreshRate

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
		if ( !("video_flags" in cfg )) cfg.video_flags <- Vid.Default
		if ( !("zorder" in cfg )) cfg.zorder <- 0
		if ( !("zorder_offset" in cfg )) cfg.zorder_offset <- 0
		if ( !("index_offset" in cfg )) cfg.index_offset <- 0
		if ( !("preserve_aspect_ratio" in cfg )) cfg.preserve_aspect_ratio <- false
		if ( !("trigger" in cfg )) cfg.trigger <- Transition.ToNewSelection
		if ( !("preset" in cfg )) cfg.preset <- ""

		// Initializing locals
		velocity = InertiaVar( 0.0, cfg.speed, 0.0 )
		velocity_int = 0
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
		mix_idx_off = 0

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
			local s = fe.add_image( "", cfg.layout.x[i], cfg.layout.y[i], cfg.layout.width[i], cfg.layout.height[i] )
			s.video_flags = cfg.video_flags
			s.preserve_aspect_ratio = cfg.preserve_aspect_ratio
			s.mipmap = true
			slots.push( s )
		}

		// To be accessed by the layout
		sel_slot = slots[selected_slot_idx]

		// Binding callbacks
		fe.add_ticks_callback( this, "on_tick" )
		fe.add_transition_callback( this, "on_transition" )
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
		if ( fe.list.size > 0 )
		{
			if ( cfg.trigger == ttype )
			{
				foreach ( s in slots ) s.video_flags = cfg.video_flags | Vid.NoAudio

				if ( abs( var ) == 1 )
					queue.push( var )
				else
					queue.push( idx2off( fe.layout.index + var, fe.layout.index ))
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
		if ( fe.list.size > 0 )
		{
			if ( cfg.trigger == ttype )
			{
				foreach ( s in slots ) s.video_flags = cfg.video_flags | Vid.NoAudio

				if ( abs( end_idx_offset ) == 1 )
					queue.push( end_idx_offset )
				else
					queue.push( idx2off( end_idx_old + end_idx_offset, end_idx_old ) )
			}

			end_idx_old = fe.layout.index
			end_idx_offset = 0
			end_navigation = true
		}
	}

	return false
}

function Wheel::on_tick( ttime )
{
	// ANIMATING THE WHEEL
	//
	if ( queue_load == 0 && queue_next == 0 ) resync = false

	if ( queue.len() > 0 )
		if ( resync == false || (( sign( queue[0] ) == velocity.dir ) && ( sign( queue[0] ) == sign( queue_next ) || ( queue_next == 0 ))))
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
				velocity_int -= dir
				queue_load += dir
				queue_next -= dir
			}
		}
	}

	// Handling audio flags
	if ( end_navigation == true && wheel_idx == fe.layout.index && queue_load == 0 )
	{
		slots[selected_slot_idx].video_flags = cfg.video_flags
		end_navigation = false
	}

	// LOADING ARTWORK

	{
		if ( velocity.get + velocity_int <= -0.5 && ( velocity.dir > 0 || cfg.speed < FRAME_TIME ))
		{
			swap_slots( 1 )
			velocity_int++
			queue_load--
			wheel_idx++
			wheel_idx = wrap( wheel_idx, fe.list.size )
			slots[cfg.slots - 1].video_flags = cfg.video_flags | Vid.NoAudio
			slots[cfg.slots - 1].file_name = fe.get_art( cfg.artwork_label,
			                                             idx2off( wheel_idx + max_idx_offset + cfg.index_offset - 0, fe.list.index ),
			                                             0,
			                                             cfg.video_flags & Art.ImagesOnly )
		}
		if ( velocity.get + velocity_int >= 0.5 && ( velocity.dir < 0 || cfg.speed < FRAME_TIME ))
		{
			swap_slots( -1 )
			velocity_int--
			queue_load++
			wheel_idx--
			wheel_idx = wrap( wheel_idx, fe.list.size )
			slots[0].video_flags = cfg.video_flags | Vid.NoAudio
			slots[0].file_name = fe.get_art( cfg.artwork_label,
			                                             idx2off( wheel_idx - max_idx_offset + cfg.index_offset + 0, fe.list.index ),
			                                             0,
			                                             cfg.video_flags & Art.ImagesOnly )
		}
	}


	// SETTING PROPERTIES
	//
	local mix_amount = velocity.get % 1.0
	if ( velocity.get <= 0 ) mix_amount += 1
	local mix_idx2 = floor( 0.5 - mix_amount )
	local mix_idx1 = mix_idx2 + 1

	// Applying interpolated layout properties to slots
	foreach ( name, prop in cfg.layout )
	{
		for ( local i = 0; i < cfg.slots; i++ )
		{
			local idx1 = wrap( mix_idx1 + i, cfg.slots )
			local idx2 = wrap( mix_idx2 + i, cfg.slots )
			slots[i][name] = mix( prop[idx1], prop[idx2], mix_amount )

			if ( name == "x" ) slots[i][name] += x
			else if ( name == "y" ) slots[i][name] += y
			else if ( name == "alpha" ) slots[i][name] = slots[i][name] / 255.0 * alpha
			else if ( name == "origin_x" ) slots[i][name] += slots[i].width / 2
			else if ( name == "origin_y" ) slots[i][name] += slots[i].height / 2
		}
	}

	// Center slots if origin not defined in the layout
	if ( !( "origin_x" in cfg.layout )) foreach ( i, s in slots ) s.origin_x = s.width / 2
	if ( !( "origin_y" in cfg.layout )) foreach ( i, s in slots ) s.origin_y = s.height / 2

	for ( local i = 0; i < cfg.slots; i++ ) slots[i].visible = slots[i].alpha
}

function Wheel::reload_slots()
{
	fe.list.page_size = min( cfg.slots, max( fe.list.size / 2, 1 ))
	wheel_idx = fe.list.index
	end_idx_old = fe.list.index
	end_idx_offset = 0
	velocity_int = 0
	velocity.set = 0.0
	queue_next = 0
	queue_load = 0

	for ( local i = 0; i < cfg.slots; i++ )
	{
		slots[i].file_name = fe.get_art( cfg.artwork_label,
		                                 i - max_idx_offset + cfg.index_offset,
		                                 0,
		                                 cfg.video_flags & Art.ImagesOnly )

		slots[i].video_flags = cfg.video_flags | Vid.NoAudio
	}

	slots[selected_slot_idx].video_flags = cfg.video_flags
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

function Wheel::swap_slots( dir )
{
	if ( dir == 1 )
		for ( local i = 1; i < cfg.slots; i++ ) slots[i].swap( slots[i - 1] )
	else
		for ( local i = cfg.slots - 1; i > 0; i-- ) slots[i].swap( slots[i - 1] )
}

// Binding the wheel to fe
fe.add_wheel <- Wheel
