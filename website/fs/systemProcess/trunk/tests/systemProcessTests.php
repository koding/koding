<?php

class pbsSystemProcessTests extends PHPUnit_Framework_TestCase
{
    public static function suite()
    {
        return new PHPUnit_Framework_TestSuite( __CLASS__ );
    }

    public function testSimpleExecution() 
    {
        $process = new pbsSystemProcess( 'echo' );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "\n", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }

    public function testInvalidExecutable() 
    {       
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/not_existant_file' );
        $this->assertEquals( $process->execute(), 127 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "sh: ", substr( $process->stderrOutput, 0, 4 ) );
        // We need to make different checks based on the system language
        switch( substr( getenv( 'LANG' ), 0, 5 ) ) 
        {
            case 'de_DE':
                $this->assertEquals( "not_existant_file: Datei oder Verzeichnis nicht gefunden\n", substr( $process->stderrOutput, -57 ) );
            break;
            case 'en_EN':
            case 'en_US':
                $this->assertEquals( "not_existant_file: No such file or directory\n", substr( $process->stderrOutput, -45 ) );
            break;
            default:
                $this->markTestSkipped('System language can not be determined. Or no testcase is implemented for your system language.');
        }
    }

    public function testOneSimpleArgument() 
    {       
        $process = new pbsSystemProcess( 'echo' );
        $process->argument( 'foobar' );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "foobar\n", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }
    
    public function testOneEscapedArgument() 
    {       
        $process = new pbsSystemProcess( 'echo' );
        $process->argument( "foobar \n 42" );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "foobar \n 42\n", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }

    public function testTwoArguments() 
    {       
        $process = new pbsSystemProcess( 'echo' );
        $process->argument( "foobar" )->argument( "42" );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "foobar 42\n", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }

    public function testStdoutOutputRedirection() 
    {       
        $process = new pbsSystemProcess( 'echo' );
        $process->argument( "foobar" );
        $process->redirect( pbsSystemProcess::STDOUT, pbsSystemProcess::STDERR );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "foobar\n", $process->stderrOutput );
    }

    public function testStdoutOutputRedirectionToFile() 
    {       
        $tmpfile = tempnam( sys_get_temp_dir(), "pbs" );
        $process = new pbsSystemProcess( 'echo' );
        $process->argument( "foobar" );
        $process->redirect( pbsSystemProcess::STDOUT, $tmpfile );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
        $this->assertEquals( "foobar\n", file_get_contents( $tmpfile ) );
        unlink( $tmpfile );
    }

    public function testStdoutOutputRedirectionBeforeArgument() 
    {       
        $process = new pbsSystemProcess( 'echo' );
        $process->redirect( pbsSystemProcess::STDOUT, pbsSystemProcess::STDERR )
                ->argument( "foobar" );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "foobar\n", $process->stderrOutput );
    }

    public function testStdoutOutputRedirectionToFileBeforeArgument() 
    {       
        $tmpfile = tempnam( sys_get_temp_dir(), "pbs" );
        $process = new pbsSystemProcess( 'echo' );
        $process->redirect( pbsSystemProcess::STDOUT, $tmpfile )
                ->argument( "foobar" );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
        $this->assertEquals( "foobar\n", file_get_contents( $tmpfile ) );
        unlink( $tmpfile );
    }

    public function testSimplePipe() 
    {
        $outputProcess = new pbsSystemProcess( 'cat' );
        $process       = new pbsSystemProcess( 'echo' );
        $process->argument( 'foobar' )
                ->pipe( $outputProcess );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "foobar\n", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }

    public function testRecursivePipe() 
    {
        $process = new pbsSystemProcess( 'echo' );
        try 
        {
            $process->pipe( $process );
            $this->fail( 'pbsSystemProcessRecursivePipeException expected.' );
        }
        catch ( pbsSystemProcessRecursivePipeException $e ) 
        {
        }
    }

    public function testCustomEnvironment() 
    {
        $process = new pbsSystemProcess( 'echo' );
        $this->assertEquals( 
            $process->argument( '"${environment_test}"', true )
                    ->environment( 
                        array( 'environment_test' => 'foobar' )
                    )
                    ->execute(),
            0
       );
       $this->assertEquals( $process->stdoutOutput, "foobar\n" );
    }

    public function testCustomWorkingDirectory() 
    {
        $process = new pbsSystemProcess( './workingDirectoryTest.sh' );
        $this->assertEquals( 
            $process->workingDirectory( __DIR__ . '/data' )
                    ->execute(),
            0
        );
        $this->assertEquals( $process->stdoutOutput, "foobar\n" );
    }

    public function testAsyncExecution() 
    {
        $process = new pbsSystemProcess( 'echo' );
        $pipes = $process->argument( 'foobar' )
                         ->execute( true );
        $output = '';
        while( !feof( $pipes[1] ) ) 
        {
            $output .= fread( $pipes[1], 4096 );
        }
        $this->assertEquals( $process->close(), 0 );
        $this->assertEquals( $output, "foobar\n" );
    }

    public function testWriteToStdin() 
    {
        $process = new pbsSystemProcess( 'cat' );
        $pipes = $process->execute( true );
        fwrite( $pipes[0], "foobar" );
        fclose( $pipes[0] );
        $output = '';
        while( !feof( $pipes[1] ) ) 
        {
            $output .= fread( $pipes[1], 4096 );
        }
        $this->assertEquals( $process->close(), 0 );
        $this->assertEquals( $output, "foobar" );
    }

    public function testCustomDescriptor() 
    {
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/fileDescriptorTest' );
        $pipes = $process->descriptor( 4, pbsSystemProcess::PIPE, 'r' )
                         ->descriptor( 5, pbsSystemProcess::PIPE, 'w' )
                         ->execute( true );
        fwrite( $pipes[4], "foobar" );
        fclose( $pipes[4] );
        $output = '';
        while( true ) 
        {
            $output .= fread( $pipes[5], 4096 );
            if ( feof( $pipes[5] ) ) 
            {
                break;
            }
        }
        $this->assertEquals( $process->close(), 0 );
        $this->assertEquals( $output, 'foobar' );
    }

    public function testCustomDescriptorToFile() 
    {
        $tmpfile = tempnam( sys_get_temp_dir(), "pbs" );
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/fileDescriptorTest' );
        $pipes = $process->descriptor( 4, pbsSystemProcess::PIPE, 'r' )
                         ->descriptor( 5, pbsSystemProcess::FILE, $tmpfile, 'a' )
                         ->execute( true );
        fwrite( $pipes[4], "foobar" );
        fclose( $pipes[4] );
        $this->assertEquals( $process->close(), 0 );
        $this->assertEquals( file_get_contents( $tmpfile ), 'foobar' );
        unlink( $tmpfile );
    }

    public function testAsyncPipe() 
    {
        $grep = new pbsSystemProcess( 'grep' );
        $grep->argument( '-v' )
             ->argument( 'baz' );

        $process = new pbsSystemProcess( 'echo' );
        $pipes = $process->argument( "foobar\nbaz" )
                         ->pipe( $grep )
                         ->execute( true );
        $output = '';
        while( !feof( $pipes[1] ) ) 
        {
            $output .= fread( $pipes[1], 4096 );
        }
        $this->assertEquals( $process->close(), 0 );
        $this->assertEquals( $output, "foobar\n" );
    }

    public function testSignal() 
    {
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/signalTest.php' );
        $pipes = $process->execute( true );
        $output = '';
        while( !feof( $pipes[1] ) ) 
        {
            $output .= fread( $pipes[1], 4096 );
            if ( $output === "ready" ) 
            {
                $output = '';
                $process->signal( pbsSystemProcess::SIGUSR1 );                
            }
        }
        $this->assertEquals( 0, $process->close() );
        $this->assertEquals( $output, "SIGUSR1 recieved" );
    }

    public function testFluentInterface() 
    {
        // This process should not be executed. It just tests the fluent
        // interface pattern.
        $process = new pbsSystemProcess( 'foobar' );
        $process->argument( '42' )
                ->pipe( new pbsSystemProcess( 'baz' ) )
                ->redirect( pbsSystemProcess::STDOUT, pbsSystemProcess::STDERR )
                ->environment( array( 'foobar' => '42' ) )
                ->workingDirectory( __DIR__ . '/data' )
                ->descriptor( 4, pbsSystemProcess::PIPE, 'r' )
                ->argument( '23' );
    }

    public function testNonZeroReturnCodeException() 
    {
        $process = new pbsSystemProcess( 'exit' );
        $process->nonZeroExitCodeException = true;
        $process->argument( '1' );
        try 
        {
            $process->execute();
            $this->fail( 'Expected pbsSystemProcessNonZeroExitCodeException' );
        }
        catch( pbsSystemProcessNonZeroExitCodeException $e ) 
        {
            /* Expected exception */
        }
    }

    public function testNonZeroReturnCodeExceptionStdout() 
    {
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/nonZeroExitCodeOutputTest.sh' );
        $process->nonZeroExitCodeException = true;
        $process->argument( 'foobar' );
        
        try 
        {
            $process->execute();
            $this->fail( 'Expected pbsSystemProcessNonZeroExitCodeException' );
        }
        catch( pbsSystemProcessNonZeroExitCodeException $e ) 
        {
            /* Expected exception */
            $this->assertEquals( 
                "foobar", $e->stdoutOutput,
                "Expected stdoutOutput not available in exception."
            );
        }
    }
    
    public function testNonZeroReturnCodeExceptionStderr() 
    {
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/nonZeroExitCodeOutputTest.sh' );
        $process->nonZeroExitCodeException = true;
        $process->argument( 'foobar' );
        $process->redirect( pbsSystemProcess::STDOUT, pbsSystemProcess::STDERR );
        
        try 
        {
            $process->execute();
            $this->fail( 'Expected pbsSystemProcessNonZeroExitCodeException' );
        }
        catch( pbsSystemProcessNonZeroExitCodeException $e ) 
        {
            /* Expected exception */
            $this->assertEquals( 
                "foobar", $e->stderrOutput,
                "Expected stderrOutput not available in exception."
            );
        }
    }

    public function testToStringMagicMethod() 
    {
        $process = new pbsSystemProcess( 'someCommand' );
        $process->argument( 'someArgument' )
                ->argument( '42' )
                ->redirect( pbsSystemProcess::STDOUT, pbsSystemProcess::STDERR );
        $this->assertEquals( 
            "someCommand 'someArgument' '42' 1>&2", (string)$process,
            'Magic __toString conversion did not return expected result.'
        );
    }

    public function testNonZeroExitCodeExceptionStdErrTruncate() 
    {
        $err = array();
        for( $i = 0; $i <= 100; ++$i ) 
        {
            $err[] = (string)$i;
        }
        $e = new pbsSystemProcessNonZeroExitCodeException( 
            1,
            'foobar',
            implode( PHP_EOL, $err ),
            'command'
        );

        $this->assertEquals( 
            52, count( explode( PHP_EOL, $e->getMessage() ) ),
            "NonZeroExitCodeException did not truncate stderr correctly"
        );
    }

    public function testNonZeroExitCodeExceptionStdErrNoTruncate() 
    {
        $err = array();
        for( $i = 0; $i <= 49; ++$i ) 
        {
            $err[] = (string)$i;
        }
        $e = new pbsSystemProcessNonZeroExitCodeException( 
            1,
            'foobar',
            implode( PHP_EOL, $err ),
            'command'
        );

        $this->assertEquals( 
            51, count( explode( PHP_EOL, $e->getMessage() ) ),
            "NonZeroExitCodeException truncated a stderr message to small for trucating"
        );
    }
}
