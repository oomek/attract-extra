///////////////////////////////////////////////////
//
// Arch - Vertical
// Wheel module preset
//
///////////////////////////////////////////////////

local preset =
{
	function init()
	{
		// Default Wheel parameters
		x <- parent.width - parent.height * 0.25
		y <- parent.height * 0.5
		slots <- 11
		speed <- 500
		artwork_label <- "wheel"
		video_flags <- Vid.ImagesOnly
		preserve_aspect_ratio <- true

		// Default preset parameters
		arch <- 60.0
		slot_aspect_ratio <- 2.0
		slot_scale <- 1.0
		slot_sel_scale <- 1.0
		slot_sel_scale_width <- 1.0
		scale_fix <- false

		layout.x <- []
		layout.width <- []
		layout.height <- []
		layout.origin_x <- []
		layout.rotation <- []
	}

	function update()
	{
		arch = clamp( arch, 1, 180 )

		local wh = parent.height

		if ( scale_fix )
			wh *= 1.0 / sin( arch * ( slots - 2.0 ) / ( slots - 1.0 ) * PI / 360.0 )
		else
			wh *= 1.0 / ( sin( arch * 1.0 / ( slots - 1.0 ) * PI / 360.0 ) * ( slots - 2.0 ))

		local angle = arch / ( slots * 2.0 - 2.0 )
		local th = sin( angle * PI / 180.0 ) * wh

		local tw = th * slot_aspect_ratio

		for ( local i = 0; i < slots; i++ )
		{
			local s = max( slot_sel_scale - fabs(( i - ( slots / 2 )) * ( slot_sel_scale - 1.0 ) / slot_sel_scale_width ), 1.0 )
			layout.origin_x[i] = th / 2.0 * slot_aspect_ratio + th / 2.0 / tan( angle * PI / 180.0 )
			layout.x[i] = layout.origin_x[i]
			layout.width[i] = tw * slot_scale * s
			layout.height[i] = th * slot_scale * s
			layout.rotation[i] = arch / 2.0 - i * angle * 2.0
		}
	}
}
return preset
