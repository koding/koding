<?php

function __autoload( $classname ) 
{
    static $mapping;
    
    if ( !isset( $mapping ) ) 
    {
        $mapping = require( __DIR__ . '/../src/autoload/systemProcess.php' );
    }

    if ( isset( $mapping[$classname] ) ) 
    {
        require( $mapping[$classname] );
    } 
}

ini_set( 'include_path', 
    ini_get( 'include_path' )
  . PATH_SEPARATOR
  . __DIR__ . '/../src'
);


