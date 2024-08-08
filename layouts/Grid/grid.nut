/*
################################################################################

Attract-Mode Frontend - Grid module v0.6
Provides animated artwork grid

2024 (c) Radek Dutkiewicz
https://github.com/oomek/attract-extra

################################################################################
*/

fe.load_module( "math" )
fe.load_module( "inertia" )

class Grid
{
    static VERSION = 0.55
    static SCRIPT_DIR = ::fe.script_dir

    // properties
    parent = null
    slots = null
    frames = null
    video = null
    x = null
    y = null
    width = null
    height = null
    slot_width = null
    slot_height = null
    spacing = null
    alpha = null
    columns = null
    rows = null
    selector = null
    sel_pos = null
    sel_flt = null
    direction = null
    page_size_org = null
    zoom = null
    active = null
    aspect_ratio_mode = null
    scale_mode = null

    sel_zoom = null
    m_outline = null

    constructor(...)
    {

        // x, y, width, height, columns, rows, spacing, surface
        if ( vargv.len() == 7 || vargv.len() == 8 )
        {
            spacing = vargv[6]
            x = vargv[0] + spacing
            y = vargv[1] + spacing
            width = vargv[2] - spacing * 2.0
            height = vargv[3] - spacing * 2.0
            columns = vargv[4]
            rows = vargv[5]
            parent = ::fe

            if ( vargv.len() == 8 )
                parent = vargv[7]
        }
        else
            throw "add_grid: Wrong number of parameters\n"

        slots = []
        frames = []
        slot_width = width / columns
        slot_height = height / rows
        direction = Dir.None
        active = true
        sel_zoom = 0
        m_outline = 0
        scale_mode = Scale.Stretch
        aspect_ratio_mode = Aspect.Keep

        zoom = Inertia( 1.0, 300 )

        page_size_org = fe.layout.page_size
        fe.layout.page_size = columns

        sel_pos = { x = (columns-1)/2, y = (rows-1)/2 }

        for ( local dy = 0; dy < rows; dy++ )
        {
            for ( local dx = 0; dx < columns; dx++ )
            {
                local obj = parent.add_rectangle( x + slot_width * dx + spacing, y + slot_height * dy + spacing, slot_width-spacing * 2.0, slot_height-spacing * 2.0 )
                obj.set_rgb( 0, 0, 0 )
                obj.set_outline_rgb( 50, 56, 80 )
                frames.push( obj )
            }
        }

        selector = parent.add_rectangle( 0, 0, 0, 0 )
        selector.outline = 0
        selector.set_rgb( 0, 0, 0 )

        for ( local dy = 0; dy < rows; dy++ )
        {
            for ( local dx = 0; dx < columns; dx++ )
            {
                local obj = parent.add_artwork( "snap", x + slot_width * dx + spacing, y + slot_height * dy + spacing, slot_width-spacing * 2.0, slot_height-spacing * 2.0 )
                obj.mipmap = false
                obj.video_flags = Vid.ImagesOnly
                obj.shader = fe.add_shader( Shader.Fragment, "crop.frag" )
                obj.index_offset = dy * columns + dx - sel_pos.x - sel_pos.y * columns
                slots.push( obj )
            }
        }

        video = parent.add_artwork( "snap" 0, 0, 0, 0 ) // 0 size, set later
        video.trigger = Transition.EndNavigation
        video.mipmap = false

        video = Inertia( video, 500, "alpha" )
        video.delay_alpha = 500
        video.tween_alpha = Tween.Linear
        video.shader = fe.add_shader( Shader.Fragment, "crop.frag" )

        fe.add_transition_callback( this, "grid_on_transition" )
        fe.add_signal_handler( this, "grid_on_signal" )
        fe.add_ticks_callback( this, "grid_on_tick" )
    }
}


function Grid::grid_on_transition( ttype, var, ttime )
{
    switch( ttype )
    {
        case Transition.ToNewList:
            // update_shaders()
        case Transition.ToNewSelection:
            switch ( direction )
            {
                case Dir.Up:
                    sel_pos.y--;
                    if ( sel_pos.y < 0 )
                        shift_slots( var )
                    else
                        foreach ( s in slots ) s.rawset_index_offset( s.index_offset + columns )
                    break

                case Dir.Down:
                    sel_pos.y++
                    if ( sel_pos.y > rows - 1 )
                        shift_slots( var )
                    else
                        foreach ( s in slots ) s.rawset_index_offset( s.index_offset - columns )
                    break

                case Dir.Left:
                    sel_pos.x--
                    foreach ( s in slots ) s.rawset_index_offset( s.index_offset + 1 )
                    break

                case Dir.Right:
                    sel_pos.x++
                    foreach ( s in slots ) s.rawset_index_offset( s.index_offset - 1 )
                    break
            }
            if ( sel_pos.y < 0 ) sel_pos.y = 0
            if ( sel_pos.y > rows - 1 ) sel_pos.y = rows - 1
            video.alpha = 0
            video.to_alpha = 255
            video.video_playing = false
            break

        case Transition.FromOldSelection:
            break
        case Transition.EndNavigation:
            direction = Dir.None
            fe.layout.page_size = page_size_org
            video.alpha = 0
            video.to_alpha = 255
            break
    }
}


function Grid::grid_on_signal( sig )
{
    if ( !active ) return false

    switch( sig )
    {
        case "up":
            direction = Dir.Up
            zoom.set = 0.0
            fe.layout.page_size = columns
            fe.signal("prev_page")
            return true

        case "down":
            direction = Dir.Down
            zoom.set = 0.0
            fe.layout.page_size = columns
            fe.signal("next_page")
            return true

        case "left":
            if ( sel_pos.x == 0 ) return true
            direction = Dir.Left
            zoom.set = 0.0
            fe.signal("prev_game")
            return true

        case "right":
            if ( sel_pos.x == columns - 1 ) return true
            direction = Dir.Right
            zoom.set = 0.0
            fe.signal("next_game")
            return true

        case "prev_game":
        case "next_game":
            zoom.to = 1.0
            if ( direction == Dir.Left )
                if ( sel_pos.x == 0 )
                {
                    direction = Dir.None
                    return true
                }

            if ( direction == Dir.Right )
                if ( sel_pos.x == columns - 1 )
                {
                    direction = Dir.None
                    return true
                }
            break

        case "prev_page":
        case "next_page":
            zoom.to = 1.0
            break

        default:
            // return false
    }
}


function Grid::grid_on_tick ( ttime )
{
    if ( active )
    {
        local active = sel_pos.x + sel_pos.y * columns
        selector.visible = true
        selector.outline_alpha = 255 * zoom.get
        selector.x = x + (sel_pos.x * slot_width) + spacing * 1.0 - zoom.get * sel_zoom
        selector.y = y + (sel_pos.y * slot_height) + spacing * 1.0 - zoom.get * sel_zoom
        selector.width = (slot_width) - spacing * 2.0 + zoom.get * sel_zoom * 2.0
        selector.height = (slot_height) - spacing * 2.0 + zoom.get * sel_zoom * 2.0

        foreach ( s in slots )
        {
            s.origin_x = 0
            s.origin_y = 0
            s.width = slot_width - spacing * 2.0
            s.height = slot_height - spacing * 2.0
        }


        slots[active].origin_x = zoom.get * sel_zoom
        slots[active].origin_y = zoom.get * sel_zoom
        slots[active].width = slot_width - spacing * 2.0 + zoom.get * sel_zoom * 2.0
        slots[active].height = slot_height - spacing * 2.0 + zoom.get * sel_zoom * 2.0

        video.x = selector.x
        video.y = selector.y
        video.width = selector.width
        video.height = selector.height

        // Set video playing state based on delayed alpha value
        video.video_playing = video.alpha
        update_shaders()
    }
    else
        selector.visible = false
}


// Optimize by reusing already loaded artwork
function Grid::shift_slots( var )
{
    if ( var > 0 )
        for ( local dx = 0; dx < columns; dx++ )
            for ( local dy = 0; dy < rows - 1; dy++ )
                slots[dx + dy * columns].swap( slots[dx + (dy + 1) * columns] )
    else if ( var < 0 )
        for ( local dx = 0; dx < columns; dx++ )
            for ( local dy = rows - 1; dy > 0; dy-- )
                slots[dx + dy * columns].swap( slots[dx + (dy - 1) * columns] )
    // update_shaders()
}

function Grid::_set( idx, val )
{
    switch( idx )
    {
        case "outline":
            if ( val != m_outline )
                foreach ( f in frames ) f.outline = val
            m_outline = val
            break

        case "sel_outline":
            selector.outline = val
            break

        case "artwork_scale":
            scale_mode = val
            break

        case "aspect_ratio":
            aspect_ratio_mode = val
            break

        case "video_flags":
            video.video_flags = val
            break

        default:
            throw( "Index " + idx + " not found." )
    }
}

function Grid::is_artwork_rotated( art )
{
    local rot = fe.game_info( Info.Rotation, art.index_offset )
    if (( rot == "90" ) || ( rot == "270" ) || ( rot == "vertical" ) || ( rot == "Vertical" ))
        return true
    else
        return false
}

function Grid::update_shaders()
{
    video.shader.set_param( "image_size", video.width, video.height )
    foreach ( s in slots )
        s.shader.set_param( "image_size", s.width, s.height )

    switch ( aspect_ratio_mode )
    {
        case Aspect.Keep:
            video.shader.set_param( "texture_size", video.texture_width * video.sample_aspect_ratio, video.texture_height )
            foreach ( s in slots )
                s.shader.set_param( "texture_size", s.texture_width, s.texture_height )
            break

        case Aspect.Force:
            if ( is_artwork_rotated( video ))
                video.shader.set_param( "texture_size", 3, 4 )
            else
                video.shader.set_param( "texture_size", 4, 3 )

            foreach ( s in slots )
            {
                if ( is_artwork_rotated( s ))
                    s.shader.set_param( "texture_size", 3, 4 )
                else
                    s.shader.set_param( "texture_size", 4, 3 )
            }
            break
    }

    switch ( scale_mode )
    {
        case Scale.Stretch:
            video.shader.set_param( "texture_size", video.width, video.height )
            foreach ( s in slots )
                s.shader.set_param( "texture_size", s.width, s.height )
            break

        case Scale.Fit:
            video.shader.set_param( "mode", 1 )
            foreach ( s in slots )
                s.shader.set_param( "mode", 1 )
            break

        case Scale.Fill:
            video.shader.set_param( "mode", 0 )
            foreach ( s in slots )
                s.shader.set_param( "mode", 0 )
            break
    }
}

Grid.Dir <-
{
    None = 0
    Up = 1
    Down = 2
    Left = 3
    Right = 4
}

Grid.Scale <-
{
    Stretch = 0
    Fit = 1
    Fill = 2
}

Grid.Aspect <-
{
    Keep = 0
    Force = 1
}

fe.add_grid <- Grid
