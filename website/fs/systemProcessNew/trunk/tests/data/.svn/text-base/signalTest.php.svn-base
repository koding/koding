#!/usr/bin/env php
<?php
declare( ticks = 1 );

function signal_handler( $signum ) 
{
    if ( $signum === SIGUSR1 ) 
    {
        echo "SIGUSR1 recieved";       
        exit( 0 );
    }
}

pcntl_signal( SIGUSR1, 'signal_handler' );

echo "ready";

// Wait the maximum of 2 second
sleep( 2 );
