///////////////////////////////////////////////////
//
// Attract-Mode Frontend - "math" module v1.0
//
// Adds additional math functions
//
// by Oomek - Radek Dutkiewicz 2021
//
///////////////////////////////////////////////////

function wrap( i, n ) { while ( i < 0 ) { i += n }; while ( i >= n ) { i -= n }; return i }
function sign( x ) { return x < 0.0 ? -1 : 1 }
function round( x ) { return floor( x + 0.5 ) }
function round2( x, p ) { return floor( x / 2.0 + 0.5 ) * 2.0 }
function floor2( x ) { return floor( x / 2.0 ) * 2.0 }
function ceil2( x ) { return ceil( x / 2.0 ) * 2.0 }
function clamp( x, min, max ) {	return x > max ? max : x < min ? min : x }
function min( a, b ) { return a < b ? a : b }
function max( a, b ) { return a > b ? a : b }
function mix( a, b, i ) { return i * ( a - b ) + b }
