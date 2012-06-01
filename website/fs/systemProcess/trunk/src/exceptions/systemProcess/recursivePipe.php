<?php

class pbsSystemProcessRecursivePipeException extends Exception 
{
    public function __construct() 
    {
        parent::__construct( 'You are trying to pipe a system process to itself. Recursive piping would create an endless loop and is therefore not possible.' );
    }
}
