/*
################################################################################

Attract-Mode Frontend - Math module v1.15
Adds additional math functions

by Oomek - Radek Dutkiewicz 2021
https://github.com/oomek/attract-extra

################################################################################
*/


// Returns 1 when x > 0, returns -1 when x < 0, returns 0 when x = 0
::sign   <- function( x ) { return x <=> 0 }

// Rounds to the nearest integer
::round  <- function( x ) { return floor( x + 0.5 ) }

// Rounds to the nearest even integer
::round2 <- function( x, p ) { return floor( x / 2.0 + 0.5 ) * 2.0 }

// Floors to the nearest even integer
::floor2 <- function( x ) { return floor( x / 2.0 ) * 2.0 }

// Ceils to the nearest even integer
::ceil2  <- function( x ) { return ceil( x / 2.0 ) * 2.0 }

// Returns a fractional part of x
::fract  <- function( x ) { return x - floor( x ) }

// Clapms x between min and max
::clamp  <- function( x, min, max ) { return x > max ? max : x < min ? min : x }

// Returns the smallest a or b
::min    <- function( a, b ) { return a < b ? a : b }

// Returns the largest a or b
::max    <- function( a, b ) { return a > b ? a : b }

// Returns a blend between a and b with using a mixing ratio x ( 0-1 range )
::mix    <- function( a, b, x ) { return x * ( a - b ) + b }

// Returns a random number in a range defined by min and max
::random <- function( min, max ) { srand( rand() * time() );
                                   return floor( rand() / RAND_MAX.tofloat() *
                                   ( max - ( min - 1.0 )) + min ) }

// Wraps x in the range 0 - max.
// It's like modulo but with correct handling of negative numbers.
::wrap   <- function( x, max ) { while ( x < 0 ) { x += max };
                                 while ( x >= max ) { x -= max };
                                 return x }
