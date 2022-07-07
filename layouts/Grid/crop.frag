//
// Attract-Mode Plus Frontend - Crop Shader v1.0
//
// 2022 (c) Radek Dutkiewicz
// https://github.com/oomek/attract-extra
//

uniform sampler2D texture;
uniform vec2 image_size;
uniform vec2 texture_size;
uniform float mode;

vec2 scaler;

void main()
{
	if ( mode == 0.0 )
	 	// crop
		scaler = min( vec2( 1.0, 1.0 ), image_size.xy / image_size.yx * texture_size.yx / texture_size.xy );
	else
	 	// fit
		scaler = max( vec2( 1.0, 1.0 ), image_size.xy / image_size.yx * texture_size.yx / texture_size.xy );

	vec2 uv = ( gl_TexCoord[0].xy - 0.5 ) * scaler + 0.5;
	vec4 pixel = texture2D( texture, uv, -0.5 );

 	// clamp to black
	uv = abs(( uv - 0.5 ) * 2.0 );
	float border = step( uv.x, 1.0 ) * step( uv.y, 1.0 );
	pixel.xyz = pixel.xyz * border;

	gl_FragColor = pixel * gl_Color;
}
