<?php

/**
 * Exception thrown if an executed application returns a non zero exit code 
 * 
 * @version //autogen//
 * @copyright Copyright (C) 2008 Jakob Westhoff. All rights reserved.
 * @author Jakob Westhoff <jakob@php.net> 
 * @license LGPLv3
 */
class pbsSystemProcessNonZeroExitCodeException extends Exception 
{
    public $exitCode;
    public $stdoutOutput;
    public $stderrOutput;
    public $command;

    public function __construct( $exitCode, $stdoutOutput, $stderrOutput, $command ) 
    {
        // Generate a useful error message including the stderr output cutoff
        // after 50 lines max.
        $truncatedStderrOutput = implode( PHP_EOL, array_slice( ( $exploded = explode( PHP_EOL, $stderrOutput ) ), 0, 50 ) )
                               . ( 
                                   ( count( $exploded ) > 50  )
                                 ? ( PHP_EOL . "... truncated after 50 lines ..." )
                                 : ( "" )
                               );

        parent::__construct( 
            'During the execution of "' . $command . '" a non zero exit code (' . $exitCode . ') has been returned:' . PHP_EOL . $truncatedStderrOutput
        );

        $this->exitCode = $exitCode;
        $this->stdoutOutput = $stdoutOutput;
        $this->stderrOutput = $stderrOutput;
        $this->command = $command;
    }
}

?>
