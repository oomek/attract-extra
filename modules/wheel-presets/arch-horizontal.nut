///////////////////////////////////////////////////
//
// Arch - Horizontal
// Wheel module preset
//
///////////////////////////////////////////////////

local preset =
{
    function init()
    {
	
		// DEFAULT WHEEL PROPEETIES
		//
		x <- parent.width - parent.height * 0.25
		y <- parent.height * 0.5
		height <- parent.height
		width <- parent.width
		slots <- 11
		speed <- 500
		artwork_label <- "wheel"
        video_flags <- Vid.ImagesOnly
        preserve_aspect_ratio <- true
        anchor <- Wheel.Anchor.Centre


		// DEFAULT PRESET PROPERTIES
		//

		// Curvature of the arch. Sign determines direction
        arch <- 90
		
		// Dynamic slot size based on slot count and ratio
		slot_aspect_ratio <- 2.0
		slot_scale <- 1.0

		// Static slot size, set to > 0 to override dynamic scaling
		slot_width <- 0
		slot_height <- 0

		// Selected slot scale and it's neighbours
		sel_slot_scale <- 1.0
		sel_slot_scale_spread <- 1.0

		scale_fix <- false

		// Layout arrays declarations. To be filled in update()
        layout.y <- []
        layout.width <- []
        layout.height <- []
        layout.origin_y <- []
        layout.rotation <- []
    }

    function update()
    {
        arch = clamp( arch, -180, 180 )
        if ( arch == 0 ) arch = 1

        local width_fixed = width

        if ( scale_fix )
            width_fixed *= 1.0 / sin( arch * ( slots - 2.0 ) / ( slots - 1.0 ) * PI / 360.0 )
        else
            width_fixed *= 1.0 / ( sin( arch * 1.0 / ( slots - 1.0 ) * PI / 360.0 ) * ( slots - 2.0 ))

        local angle = arch / ( slots * 2.0 - 2.0 )
        local half_width = sin( angle * PI / 180.0 ) * width_fixed * 0.5

        local slot_w = 0
        local slot_h = 0

        if ( slot_width == 0 ) slot_w = half_width * 2.0
        else slot_w = slot_width

        if ( slot_height == 0 ) slot_h = slot_w / slot_aspect_ratio
        else slot_h = slot_height

        local slot_ar = slot_h / slot_w
        if ( arch < 0 ) slot_ar = -slot_ar

        for ( local i = 0; i < slots; i++ )
        {
            local sel_scale = max( sel_slot_scale - fabs(( i - ( slots / 2 )) * ( sel_slot_scale - 1.0 ) / sel_slot_scale_spread ), 1.0 )
            layout.origin_y[i] = half_width * slot_ar + half_width / tan( angle * PI / -180.0 )
            layout.y[i] = layout.origin_y[i]
            layout.width[i] = slot_w * slot_scale * sel_scale
            layout.height[i] = slot_h * slot_scale * sel_scale
            layout.rotation[i] = arch / 2.0 - i * angle * 2.0
        }
    }
}
return preset
