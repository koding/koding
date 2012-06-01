<?php

class pbsSystemProcessInvalidCustomDescriptorException extends Exception 
{
    public function __construct( $fd ) 
    {
        parent::__construct( 'The specified custom file descriptor "' . (string)$fd . '" is invalid. Maybe you are trying to override a default descriptor (<3).' );
    }
}
