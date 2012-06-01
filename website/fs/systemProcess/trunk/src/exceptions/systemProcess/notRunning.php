<?php

class pbsSystemProcessNotRunningException extends Exception 
{
    public function __construct() 
    {
        parent::__construct( 'The process is not running.' );
    }
}
