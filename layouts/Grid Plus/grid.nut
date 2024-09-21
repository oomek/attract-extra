/*
################################################################################

Attract-Mode Frontend - Grid module v1.0
Provides animated artwork grid

2024 (c) Radek Dutkiewicz
https://github.com/oomek/attract-extra

################################################################################
*/

fe.load_module( "math" )
fe.load_module( "inertia" )

class Grid
{
    static VERSION = 1.0
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
    sel_y_old = null
    direction = null
    page_size_org = null
    zoom = null
    active = null
    scale_mode = null
    aspect_ratio_mode = null
    first_move = null

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
        first_move = true

        zoom = Inertia( 1.0, 300 )

        page_size_org = fe.layout.page_size
        fe.layout.page_size = columns

        sel_pos = { x = fe.list.index % columns, y = 0 }
        sel_y_old = -1

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

        video = parent.add_image( "" 0, 0, 0, 0 )
        video.shader = fe.add_shader( Shader.Fragment, "crop.frag" )

        fe.add_transition_callback( this, "on_transition" )
        fe.add_signal_handler( this, "on_signal" )
        fe.add_ticks_callback( this, "on_tick" )
    }
}

function calculate_sel_pos_y(offset)
{
    local effective_offset = offset % fe.list.size  // Normalize the offset
    local new_idx = modulo( fe.list.index + effective_offset, fe.list.size )
    local new_row = ( new_idx / columns ).tointeger() + 1
    local total_rows = ( fe.list.size + columns - 1 ) / columns
    local visible_rows = min( rows, total_rows )

    // Calculate the base y position
    local base_y = new_row - total_rows + visible_rows - 1

    // Ensure base_y is not negative
    base_y = max( 0, base_y )

    // Apply the min-max logic
    local ret = min( max( sel_pos.y, base_y ), new_row - 1 )

    return ret
}

function Grid::set_active( state )
{
    active = state
    zoom.set = 0.0
    zoom.to = 1.0
}

function Grid::hide_grid()
{
    foreach ( s in slots ) s.visible = false
    foreach ( f in frames ) f.visible = false
    selector.visible = false
    video.visible = false
    video.video_playing = false
    video.file_name = ""
}

function Grid::load_video()
{
    video.file_name = fe.get_art( "snap" )
    video.video_playing = true
    video.visible = true
}

function Grid::on_transition( ttype, var, ttime )
{
    switch( ttype )
    {
        case Transition.ToNewList:
            // store and restore the old sel_pos.y when in the colones list and back
            if ( fe.layout.clones_list )
            {
                sel_y_old = sel_pos.y
            }
            else if ( sel_y_old >= 0 )
            {
                sel_pos.y = sel_y_old
                sel_y_old = -1
            }
            sel_pos.x = ( fe.list.index ) % columns
            sel_pos.y = calculate_sel_pos_y(0)
            foreach ( i, s in slots ) s.index_offset = i - sel_pos.x - sel_pos.y * columns
            hide_out_of_range_slots()
            if ( fe.list.size == 0 ) hide_grid()
            else load_video()
            break

        case Transition.ToNewSelection:
            switch ( direction )
            {
                case Dir.Up:
                    sel_pos.y--;

                    if ( sel_pos.y < 0 )
                        shift_slots( var ) // optimized scrolling

                    sel_pos.y = calculate_sel_pos_y( var )
                    break

                case Dir.Down:
                    sel_pos.y++

                    if ( sel_pos.y > rows - 1 )
                        shift_slots( var ) // optimized scrolling

                    sel_pos.y = calculate_sel_pos_y( var )
                    break

                case Dir.Left:
                    break

                case Dir.Right:
                    break

                case Dir.Letter:
                case Dir.None:
                    sel_pos.x = ( fe.list.index + var ) % columns
                    sel_pos.y = calculate_sel_pos_y( var )
                    break

                case Dir.Page:
                    sel_pos.x = ( fe.list.index + var ) % columns
                    sel_pos.y = calculate_sel_pos_y( var )
                    break
            }

            if ( sel_pos.y < 0 ) sel_pos.y = 0
            if ( sel_pos.y > rows - 1 ) sel_pos.y = rows - 1
            video.video_playing = false

            // This works when holding navigation
            sel_pos.x = ( fe.list.index + var ) % columns

            //This works when pressed Down on the last row
            if ( fe.list.index + var > fe.list.size - 1 )
                sel_pos.x = ( fe.list.index - fe.list.size + var ) % columns

            //This works when pressed Up on the first row
            if ( fe.list.index + var < 0 )
                sel_pos.x = ( fe.list.index + fe.list.size + var ) % columns

            foreach ( i, s in slots ) s.rawset_index_offset( i - sel_pos.x - sel_pos.y * columns )

            break
        case Transition.FromOldSelection:
            zoom.set = 0.0
            if ( first_move || fe.list.index == 0 || fe.list.index == fe.list.size - 1 )
            {
                load_video()
                zoom.to = 1.0
            }
            first_move = false
            hide_out_of_range_slots()
            break

        case Transition.EndNavigation:
            zoom.to = 1.0
            direction = Dir.None
            fe.layout.page_size = page_size_org
            first_move = true
            load_video()
            break
    }
}

function Grid::on_signal( sig )
{
    if ( fe.list.size == 0 )
    {
        switch( sig )
        {
            case "right":
            case "prev_game":
            case "next_game":
            case "prev_page":
            case "next_page":
            case "prev_favourite":
            case "next_favourite":
            case "prev_letter":
            case "next_letter":
            case "select":
                return true
        }
    }

    if ( !active )
    {
        switch( sig )
        {
            case "prev_page":
            case "next_page":
            case "prev_favourite":
            case "next_favourite":
            case "prev_letter":
            case "next_letter":
                return true
            default:
                return false
        }
    }

    switch( sig )
    {
        case "up":
            direction = Dir.Row
            fe.layout.page_size = columns

            if ( fe.list.index % columns == fe.list.index )
            {
                sel_pos.y = rows
                fe.layout.page_size = max ( fe.list.index, ( fe.list.size - 1 ) % columns ) + 1
            }

            fe.signal("prev_page")
            return true

        case "down":
            direction = Dir.Row
            fe.layout.page_size = columns

            local last_row_start = ( fe.list.size - 1 ) - (( fe.list.size - 1 ) % columns )
            if ( fe.list.index >= last_row_start )
            {
                sel_pos.y = -1
                fe.layout.page_size = ( fe.list.size - 1 ) % columns + 1
            }
            else if ( fe.list.index >= last_row_start - columns )
                fe.layout.page_size = min( columns, ( fe.list.size - 1 ) - fe.list.index )

            fe.signal("next_page")
            return true

        case "left":
            if ( sel_pos.x == 0 ) return true
            direction = Dir.Left
            fe.signal("prev_game")
            return true

        case "right":
            if ( !active ) return true
            if ( sel_pos.x == columns - 1 ) return true
            if ( fe.list.index + 1 == fe.list.size ) return true
            direction = Dir.Right
            fe.signal("next_game")
            return true

        case "prev_game":
        case "next_game":
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
            zoom.to = 1.0
            if ( direction == Dir.Page )
                fe.layout.page_size = columns * rows

            if ( direction == Dir.Up )
                fe.layout.page_size = columns

            if ( direction == Dir.Row )
                 direction = Dir.Up

            if ( direction == Dir.None )
            {
                direction = Dir.Page

                fe.layout.page_size = columns * rows
                local total_rows = ( fe.list.size + columns - 1 ) / columns

                if ( fe.list.index - fe.layout.page_size < 0 )
                    fe.layout.page_size -= total_rows * columns - fe.list.size
            }

            fe.layout.page_size = min( fe.layout.page_size, fe.list.size )
            break

        case "next_page":
            zoom.to = 1.0
            if ( direction == Dir.Page )
                fe.layout.page_size = columns * rows

            if ( direction == Dir.Down )
                fe.layout.page_size = columns

            if ( direction == Dir.Row )
                 direction = Dir.Down

            if ( direction == Dir.None )
            {
                direction = Dir.Page

                fe.layout.page_size = columns * rows
                local total_rows = ( fe.list.size + columns - 1 ) / columns

                if ( fe.list.index + fe.layout.page_size > fe.list.size - 1 )
                    fe.layout.page_size -= total_rows * columns - fe.list.size
            }

            fe.layout.page_size = min( fe.layout.page_size, fe.list.size )
            break

        case "prev_letter":
        case "next_letter":
            zoom.to = 1.0
            direction = Dir.Letter
            break

        default:
            return false
    }

    return false
}

function Grid::hide_out_of_range_slots()
{
    foreach ( i, s in slots )
    {
        if ( s.index_offset + ::fe.list.index > ::fe.list.size - 1 )
        {
            slots[i].visible = false
            frames[i].visible = false
        }
        else if ( s.index_offset + ::fe.list.index < 0 )
        {
            slots[i].visible = false
            frames[i].visible = false
        }
        else
        {
            slots[i].visible = true
            frames[i].visible = true
        }
    }
}

function Grid::on_tick ( ttime )
{
    if ( fe.list.size == 0 )
    {
        sel_pos.y = 0
        selector.visible = false
    }
    else
        selector.visible = true

    local active_slot = sel_pos.x + sel_pos.y * columns
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

    slots[active_slot].origin_x = zoom.get * sel_zoom
    slots[active_slot].origin_y = zoom.get * sel_zoom
    slots[active_slot].width = slot_width - spacing * 2.0 + zoom.get * sel_zoom * 2.0
    slots[active_slot].height = slot_height - spacing * 2.0 + zoom.get * sel_zoom * 2.0

    video.x = selector.x
    video.y = selector.y
    video.width = selector.width
    video.height = selector.height
    video.alpha = 255 * zoom.get

    update_shaders()
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
    Letter = 5
    Page = 6
    Row = 7
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
