///////////////////////////////////////////////////
//
// Attract-Mode Frontend - "inertia" module v1.0
//
// Adds animation to object's properties
//
// by Oomek - Radek Dutkiewicz 2021
//
///////////////////////////////////////////////////

class Inertia
{
	object = null
	props = null

	constructor ( _object, _time, _spring, ... )
	{
		if ( _object instanceof ::Inertia )
		{
			object = _object.object
			props = _object.props
		}
		else
		{
			object = _object
			props = {}
			::fe.add_ticks_callback( this, "on_tick" )
		}

		foreach ( p in vargv )
		{
			local prop = Property()
			prop.name = p
			prop.running = false
			prop.from = object[p].tofloat()
			prop.to = object[p].tofloat()
			prop.buffer = ::array( 4, object[p] )
			if ( _spring.tofloat() < 0.0 )
			{
				prop.spring = -_spring.tofloat()
				prop.bounce = true
			}
			else
			{
				prop.spring = _spring.tofloat()
				prop.bounce = false
			}
			set_speed( prop, _time )
			props[p] <- prop
		}
	}

	// 4-pole resonant low pass filter
	function inertia( p )
	{
		local b = p.buffer
		b[0] += p.speed * ( p.to - b[0] + p.feedback * ( b[0] - b[1] ))
		b[1] += p.speed * ( b[0] - b[1] )
		b[2] += p.speed * ( b[1] - b[2] )
		b[3] += p.speed * ( b[2] - b[3] )

		if ( ::fabs(b[0] - p.to) + ::fabs(b[3] - p.to) < 0.125 )
		{
			p.running = false
			b = ::array( 4, p.to )
		}

		if ( p.bounce )
			if( b[3] >= p.to )
				p.from = p.to * 2 - b[3]
			else
				p.from = b[3]

		else
			p.from = b[3]

		return p.from
	}

	function on_tick( tick_time )
	{
		foreach ( p in props )
		{
			if ( p.running )
			{
				local a = inertia( p )
				object[p.name] = a
			}
		}
	}

	function set_speed( p, _time )
	{
		if ( _time < 1.0 ) _time = 1.0
		p.speed = ::sin(( 4000.0 * ::PI ) / ( 8000.0 + ScreenRefreshRate * _time.tofloat() ))
		p.feedback = p.spring + p.spring / ( 1.0 - p.speed )
	}

	function _set( idx, val )
	{
		if ( idx == "time")
		{
			foreach ( p in props )
				set_speed( p, val )
			return
		}
		else if ( idx.find( "to_" ) == 0 )
		{
			local p = idx.slice(3)
			if( p in props )
			{
				props[p].running = true
				props[p].to = val
			}
		}
		else if ( idx.find( "from_" ) == 0 )
		{
			local p = idx.slice(5)
			if( p in props )
			{
				props[p].running = true
				local delta = val - props[p].from
				props[p].from += delta
				props[p].buffer[0] += delta
				props[p].buffer[1] += delta
				props[p].buffer[2] += delta
				props[p].buffer[3] += delta
			}
		}
		else if ( idx in props )
		{
			props[idx].running = false
			object[idx] = val
			props[idx].from = val
			props[idx].to = val
			props[idx].buffer[0] = val
			props[idx].buffer[1] = val
			props[idx].buffer[2] = val
			props[idx].buffer[3] = val
		}
		else
			object[idx] = val
	}

	function _get( idx )
	{
		if ( idx.find( "to_" ) == 0 )
		{
			local p = idx.slice(3)
			if ( p in props )
				return props[p].to
		}
		else if ( idx.find( "from_" ) == 0 )
		{
			local p = idx.slice(5)
			if ( p in props )
				return props[p].from
		}
		else
			return object[idx]
	}

	function offset( x, y )
	{
		if ( "x" in props )
		{
			local offset = x - object.x
			props["x"].running = true
			props["x"].from += offset
			props["x"].to += offset
			props["x"].buffer[0] += offset
			props["x"].buffer[1] += offset
			props["x"].buffer[2] += offset
			props["x"].buffer[3] += offset
		}
		if ( "y" in props )
		{
			props["y"].running = true
			props["y"].from += x
			props["y"].to += x
			props["y"].buffer[0] += x
			props["y"].buffer[1] += x
			props["y"].buffer[2] += x
			props["y"].buffer[3] += x
		}
	}

	// function wrappers
	function swap( obj )
	{
		object.swap( obj )
	}

	function set_rgb( r, g, b )
	{
		object.set_rgb( r, g, b )
	}

	function set_bg_rgb( r, g, b )
	{
		object.set_bg_rgb( r, g, b )
	}

	function set_pos( x, y, width = null, height = null)
	{
		if ( !width && !height )
			object.set_pos( x, y )
		else
			object.set_pos( x, y, width, height )
	}

	function set_sel_rgb( r, g, b )
	{
		object.set_sel_rgb( r, g, b )
	}

	function set_selbg_rgb( r, g, b )
	{
		object.set_selbg_rgb( r, g, b )
	}

	function swap( other_img )
	{
		object.swap( other_img )
	}

	function fix_masked_image()
	{
		object.fix_masked_image()
	}

	function load_from_archive( archive, filename )
	{
		object.load_from_archive( archive, filename )
	}

	function rawset_index_offset( offset )
	{
		object.rawset_index_offset( offset )
	}

	function rawset_filter_offset( offset )
	{
		object.rawset_filter_offset( offset )
	}
}

class Inertia.Property
{
	running = null
	from = null
	to = null
	buffer = null
	name = null
	speed = null
	spring = null
	bounce = null
	feedback = null
}

class InertiaVar
{
	m_variable = null
	m_from = null
	m_to = null
	m_buffer = null
	m_running = null
	m_speed = null
	m_spring = null
	m_feedback = null

	constructor ( _val, _time, _spring )
	{
		m_variable = _val
		m_from = _val
		m_to = _val
		m_running = false
		m_buffer = ::array( 4, _val )
		m_spring = _spring.tofloat()
		set_speed( _time )
		::fe.add_ticks_callback( this, "on_tick_var" )
	}

	// 4-pole resonant low pass filter
	function inertia()
	{
		m_buffer[0] += m_speed * ( m_to - m_buffer[0] + m_feedback * ( m_buffer[0] - m_buffer[1] ))
		m_buffer[1] += m_speed * ( m_buffer[0] - m_buffer[1] )
		m_buffer[2] += m_speed * ( m_buffer[1] - m_buffer[2] )
		m_buffer[3] += m_speed * ( m_buffer[2] - m_buffer[3] )

		if ( ::fabs(m_buffer[0] - m_to) + ::fabs(m_buffer[3] - m_to) < 0.001 )
		{
			m_running = false
			m_buffer = ::array( 4, m_to )
		}

		m_from = m_buffer[3]

		return m_from
	}

	function on_tick_var( tick_time )
	{
		if ( m_running )
			m_variable = inertia()
	}

	function set_speed( _time )
	{
		if ( _time < 1.0 ) _time = 1.0
		m_speed = ::sin(( 4000.0 * ::PI ) / ( 8000.0 + ScreenRefreshRate * _time.tofloat() ))
		m_feedback = m_spring + m_spring / ( 1.0 - m_speed )
	}

	function _set( idx, val )
	{
		if ( idx == "time")
		{
			set_speed( val )
			return
		}
		else if ( idx == "to" )
		{
			m_running = true
			m_to = val
		}
		else if ( idx == "from" )
		{
			m_running = true
			local delta = val - m_from
			m_from += delta
			m_buffer[0] += delta
			m_buffer[1] += delta
			m_buffer[2] += delta
			m_buffer[3] += delta
		}
		else if ( idx == "set" )
		{
			m_running = false
			m_variable = val
			m_from = val
			m_to = val
			m_buffer[0] = val
			m_buffer[1] = val
			m_buffer[2] = val
			m_buffer[3] = val
		}
		else
		{
			m_variable = val
		}
	}

	function _get( idx )
	{
		if ( idx == "to" )
		{
			return m_to
		}
		else if ( idx == "from" )
		{
			return m_from
		}
		else if ( idx == "get" )
		{
			return m_from
		}
		else if ( idx == "dir")
		{
			if ( m_buffer[2] < m_buffer[3] ) return 1
			else if ( m_buffer[2] > m_buffer[3] ) return -1
			else return 0
		}
	}
}
