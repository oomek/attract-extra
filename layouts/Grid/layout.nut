/*
################################################################################

Attract-Mode Plus Frontend - Grid layout v0.75

2022 (c) Radek Dutkiewicz
https://github.com/oomek/attract-extra

################################################################################
*/

class UserConfig </ help="Grid layout with custom filters menu" />
{
    </ label="Columns", help="Number of columns to display", options="1,2,3,4,5", per_display="true", order=1 />
    columns = "3"

    </ label="Rows", help="Number of rows to display", options="1,2,3,4,5", per_display="true", order=2 />
    rows = "3"

    </ label="Pixel Font", help="Specifies when to use pixel style font.", options="Always,Never,Auto", per_display="true", order=3 />
    pixel_font = "Auto"

    </ label="Selected Game", help="Specifies what to show in the selected game slot.", options="Snap,Video,Video Muted", per_display="true", order=4 />
    video_flags = "Video"

    </ label="Artwork Scale", help="Set scaling mode inside the artwork slots.", options="Stretch,Fit,Fill", per_display="true", order=5 />
    scale_mode = "Stretch"

    </ label="Aspect Ratio", help="Set artwork's aspect ratio type.", options="Keep,Force 4:3", per_display="true", order=6 />
    aspect_ratio = "Keep"

    </ label="Enable Sounds", help="Enables or disables in-built sounds.", options="Yes,No", per_display="true", order=7 />
    sounds = "Yes"
}
cfg <- fe.get_config()


fe.do_nut( "grid.nut" )
fe.load_module( "inertia" )

fe.load_module( "config" )
local selection_speed = ::fe.get_config_value( "selection_speed_ms" ).tointeger()

local flw = fe.layout.width
local flh = fe.layout.height

// base dimension -  width or height, whichever is smaller
local flb = flw > flh ? flh : flw

// Round to integer if base is < 480
local fls = flb > 480.0 ? flb / 240.0 : round( flb / 240.0 )

// Clamp scale to 1.0
fls = fls > 1.0 ? fls : 1.0

local FONT = "fonts/Barlow.ttf"
local FONT_SIZE = fls * 12

local UI_SOUND_NAV = fe.add_sound( "sounds/amp_nav.wav" )
local UI_SOUND_SELECT = fe.add_sound( "sounds/amp_select.wav" )
local UI_SOUND_BACK = fe.add_sound( "sounds/amp_back.wav" )

local SOUND_STATE = cfg["sounds"] == "Yes" ? true : false

switch ( cfg["pixel_font"] )
{
    case "Always":
        FONT_SIZE = round(fls) * 11
        FONT = "fonts/Attract.ttf"
        break

    case "Never":
        break

    case "Auto":
    if ( fls <= 2.0 )
    {
        FONT_SIZE = fls * 11
        FONT = "fonts/Attract.ttf"
    }
}


local header_height = round( flb / 12.0 ) // 20 pixels on 240p base
local side_width = round( flb * 0.45 )    // 216 pixels on 240p base
local grid_margin = round( flb / 60.0 )   // 4 pixels on 240p base

local sidebar_open = false
local selected_filter = 0
local keyrepeat_timer = 0
local keyrepeat_delay = 500
local key_pressed = false
local nav_margin = 2
local visible_filters = round( flh / header_height )

// Blue background
local bg = fe.add_rectangle( 0, 0, flw, flh )
bg.set_rgb( 15, 19, 30 )


// Grid module on a surface
local grid_surface = fe.add_surface( flw, flh )
      grid_surface.mipmap = false
      grid_surface.smooth = false
      grid_surface.set_pos( 0, 0, flw, flh )

local grid_bg = grid_surface.add_rectangle( 0, header_height, grid_surface.width, grid_surface.height - header_height * 2.0 )
      grid_bg.set_rgb( 30, 38, 60 )

local grid = fe.add_grid( 0, header_height, flw, flh - header_height * 2.0 , cfg["columns"].tointeger(), cfg["rows"].tointeger(), grid_margin, grid_surface )
      grid.outline = fls * 2.0
      grid.sel_outline = fls * 2.0
      grid.sel_zoom = fls * 6.0
      grid.sel_zoom = grid_margin * 0.75

switch ( cfg["scale_mode"] )
{
    case "Stretch":
        grid.artwork_scale = Grid.Scale.Stretch
        break
    case "Fit":
        grid.artwork_scale = Grid.Scale.Fit
        break
    case "Fill":
        grid.artwork_scale = Grid.Scale.Fill
        break
}

switch ( cfg["aspect_ratio"] )
{
    case "Keep":
        grid.aspect_ratio = Grid.Aspect.Keep
        break
    case "Force 4:3":
        grid.aspect_ratio = Grid.Aspect.Force
        break
}

switch ( cfg["video_flags"] )
{
    case "Snap":
        grid.video_flags = Vid.ImagesOnly
        break
    case "Video":
        grid.video_flags = Vid.NoAutoStart
        break
    case "Video Muted":
        grid.video_flags = Vid.NoAutoStart | Vid.NoAudio
}

// Clones list surface
local clones_surface = fe.add_surface( flw, flh )
      clones_surface.mipmap = false
      clones_surface.smooth = false
      clones_surface.set_pos( flw, 0, flw, flh )

local clones_bg = clones_surface.add_rectangle( 0, header_height, clones_surface.width, clones_surface.height - header_height * 2.0 )
      clones_bg.set_rgb( 30, 38, 60 )

local clones_list = clones_surface.add_listbox( 0, header_height, clones_surface.width, clones_surface.height - header_height * 2.0 )
      clones_list.font = FONT
      clones_list.char_size = FONT_SIZE
      clones_list.align = Align.MiddleLeft
      clones_list.alpha = 200
      clones_list.sel_alpha = 200
      clones_list.selbg_alpha = 0
      clones_list.set_sel_rgb( 255, 255, 255 )

local clones_selector = clones_surface.add_rectangle( 0, flh / 2.0 - flh / 22.0, flw, flh / 11.0 )
      clones_selector.alpha = 0
      clones_selector.outline = -fls * 2.0


// List entry
local list_size = grid_surface.add_text( "[ListEntry] / [ListSize]", 0, 0, grid_surface.width, header_height )
      list_size.align = Align.MiddleRight
      list_size.font = FONT
      list_size.char_size = FONT_SIZE
      list_size.alpha = 200
      list_size.margin = grid_margin * 2.0


// Current filter
local filter_name = grid_surface.add_text( "<  [FilterName]", 0, 0, grid_surface.width / 2, header_height )
      filter_name.align = Align.MiddleLeft
      filter_name.font = FONT
      filter_name.char_size = FONT_SIZE
      filter_name.alpha = 200
      filter_name.margin = grid_margin * 2.0


// Game title
local title = grid_surface.add_text( "[Title]", 0, grid_surface.height - header_height, grid_surface.width, header_height )
      title.align = Align.MiddleLeft
      title.font = FONT
      title.char_size = FONT_SIZE
      title.alpha = 255
      title.margin = grid_margin * 2.0


// Sidebar with filter names
local filters = []
foreach ( i, f in fe.filters )
{
    local obj = fe.add_text( f.name, 0, i * header_height, side_width, header_height )
    obj.align = Align.MiddleLeft
    obj.font = FONT
    obj.char_size = FONT_SIZE
    obj.alpha = 200
    obj.margin = grid_margin * 1.5
    filters.push( obj )
}

local filter_selector = fe.add_rectangle( 0, 0, 0, 0 ) // 0 size, set later
      filter_selector.outline = fls * -2.0
      filter_selector.alpha = 0
      filter_selector.visible = false


// Favourites stars
local star = grid_surface.add_image( "images/star192.png" )
      star.mipmap = true
      star.anchor = Anchor.TopRight

local stars = []
foreach ( s in grid.slots )
{
    local obj = grid_surface.add_clone( star )
    obj.x = s.width + s.x
    obj.y = s.y
    obj.width = max( fls * 12.0, 21 )
    obj.height = max( fls * 12.0, 21 )
    stars.push( obj )
}
star.visible = false


// Inertias

// Add Inertia to a variable
local selector_zoom = Inertia( 1.0, 300 )

// Animate grid surface
grid_surface = Inertia( grid_surface, 300, "x", "alpha" )

// Animate clones surface
clones_surface = Inertia( clones_surface, 300, "x" )

// Grid selector color cycle
grid.selector = Inertia( grid.selector, 3000, "outline_red", "outline_green", "outline_blue" )
grid.selector.tween_all = Tween.FullSine
grid.selector.loop_all = true
grid.selector.to_all = 100
grid.selector.delay_outline_green = -1000
grid.selector.delay_outline_blue = -2000

// Animate filters menu
local filters_dy = Inertia( 0.0, 300 )


function update_stars()
{
    foreach ( i, s in stars )
        s.visible = fe.game_info( Info.Favourite, grid.slots[i].index_offset ) == "1" ? true : false
}


function update_filters( direction )
{
    selected_filter += direction
    if ( selected_filter < 0 )
        selected_filter = 0
    else if ( direction < 0 )
        UI_SOUND_NAV.playing = SOUND_STATE

    if ( selected_filter > fe.filters.len() - 1 )
        selected_filter = fe.filters.len() - 1
    else if ( direction > 0 )
        UI_SOUND_NAV.playing = SOUND_STATE

    // Upper bound
    if ( selected_filter - filters_dy.to < nav_margin )
        filters_dy.to = (selected_filter - nav_margin)
    if ( filters_dy.to < 0 )
        filters_dy.to = 0

    // Lower bound
    if ( selected_filter - filters_dy.to > visible_filters - nav_margin - 1 )
        filters_dy.to = (selected_filter + nav_margin + 1 - visible_filters)
    if ( filters_dy.to + visible_filters > filters.len() )
        filters_dy.to = (filters.len() - visible_filters)

    filters_dy.to = max( filters_dy.to, 0.0 )
}


fe.add_transition_callback( "on_transition" )
function on_transition( ttype, var, ttime )
{
    switch( ttype )
    {
        case Transition.StartLayout:
            selected_filter = fe.list.filter_index
            filters_dy.to = ( selected_filter - visible_filters / 2 )
            update_filters( 0 )
            break
        case Transition.ToNewList:
            if ( fe.layout.clones_list )
            {
                grid.active = false
                clones_surface.to_x = 0.0
            }
            else
            {
                grid.active = true
                clones_surface.to_x = flw
            }

            selected_filter = fe.list.filter_index
            update_stars()
        case Transition.EndNavigation:
            break

        case Transition.ToNewSelection:
            UI_SOUND_NAV.playing = SOUND_STATE
            break

        case Transition.FromOldSelection:
            update_stars()
            break

        case Transition.ToGame:
            if ( UI_SOUND_SELECT.playing ) return true
            break
    }
}


fe.add_signal_handler( "on_signal" )
function on_signal( sig )
{
    if ( sidebar_open )
    {
        switch( sig )
        {
            case "select":
                UI_SOUND_SELECT.playing = SOUND_STATE
                fe.list.filter_index = selected_filter
                filter_selector.visible = false
                grid.active = true
                grid_surface.to_x = 0.0
                grid_surface.to_alpha = 255
                sidebar_open = false
                return true

            case "up":
                update_filters( -1 )
                selector_zoom.set = 0.0
                selector_zoom.to = 1.0
                key_pressed = true
                return true

            case "down":
                update_filters( 1 )
                selector_zoom.set = 0.0
                selector_zoom.to = 1.0
                key_pressed = true
                return true

            case "left":
                return true

            case "right":
            case "back":
                filter_selector.visible = false
                grid.active = true
                grid_surface.to_x = 0.0
                grid_surface.to_alpha = 255
                sidebar_open = false
                grid.video.to_alpha = 255
                return true
        }
        return false
    }
    else
    {
        switch( sig )
        {
            case "right":
                if ( fe.layout.clones_list )
                    return true
                break

            case "left":
                if ( fe.layout.clones_list )
                {
                    fe.signal("back")
                    return true
                }

                if ( grid.sel_pos.x == 0 )
                {
                    selected_filter = fe.list.filter_index
                    update_filters( 0 )
                    filter_selector.visible = true
                    grid.active = false
                    grid_surface.to_x = side_width
                    grid_surface.to_alpha = 100
                    sidebar_open = true
                    return true
                }
                break

            case "next_game":
            case "prev_game":
            case "next_page":
            case "prev_page":
                break

            case "select":
                UI_SOUND_SELECT.playing = SOUND_STATE
                break
        }
    }
}


fe.add_ticks_callback( "on_tick" )
function on_tick( ttime )
{
    if ( !fe.overlay.is_up )
    {
        if ( key_pressed )
        {
            keyrepeat_timer = ttime
            key_pressed = false
            keyrepeat_delay = 500
        }

        if( sidebar_open && ( ttime - keyrepeat_timer > keyrepeat_delay ))
        {
            keyrepeat_timer = ttime
            keyrepeat_delay = selection_speed
            if ( fe.get_input_state( "up" )) update_filters( -1 )
            if ( fe.get_input_state( "down" )) update_filters( 1 )
        }
    }

    foreach ( i, f in filters )
    {
        f.x = grid_surface.x - side_width
        f.y = i * header_height - filters_dy.get * header_height
    }

    if ( sidebar_open )
    {
        grid.video.alpha = 0
        grid.video.video_playing = false

        filter_selector.outline = fls * 2.0 * selector_zoom.get
        filter_selector.x = filters[selected_filter].x + fls * 2.0 * ( 2.0 - selector_zoom.get )
        filter_selector.y = filters[selected_filter].y + fls * 2.0 * ( 2.0 - selector_zoom.get )
        filter_selector.width = filters[selected_filter].width + fls * 4.0 * ( selector_zoom.get - 2.0 )
        filter_selector.height = filters[selected_filter].height + fls * 4.0 * ( selector_zoom.get - 2.0 )
        filter_selector.outline_red = grid.selector.outline_red
        filter_selector.outline_green = grid.selector.outline_green
        filter_selector.outline_blue = grid.selector.outline_blue
        filter_selector.outline_alpha = 255.0 * selector_zoom.get
    }
    else
    {
        title.red = grid.selector.outline_red
        title.green = grid.selector.outline_green
        title.blue = grid.selector.outline_blue

        foreach ( i, s in grid.slots )
        {
            stars[i].x = s.width + s.x - s.origin_x
            stars[i].y = s.y - s.origin_y
        }
    }

    if ( fe.layout.clones_list )
    {
        title.visible = false
        clones_selector.set_outline_rgb( title.red, title.green, title.blue )
    }
    else title.visible = true
}
