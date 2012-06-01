<?php
require_once( __DIR__ . '/environment.php' );

class pbsSystemProcessTests extends PHPUnit_Framework_TestCase
{
    protected static $win = false;

    public static function suite()
    {
        self::$win = ( strtoupper( substr( PHP_OS, 0, 3)) === 'WIN' );
        return new PHPUnit_Framework_TestSuite( __CLASS__ );
    }

    public function testSimpleExecution() 
    {
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( PHP_EOL, $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }

    public function testInvalidExecutable() 
    {       
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/not_existant_file' );
        $this->assertNotEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertNotSame( false, strpos( $process->stderrOutput, 'not_existant_file' ) );
    }

    public function testOneSimpleArgument() 
    {       
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $process->argument( 'foobar' );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "foobar" . PHP_EOL, $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }
    
    public function testOneEscapedArgument() 
    {       
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $process->argument( "foobar 42" );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "foobar 42" . PHP_EOL, $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }

    public function testTwoArguments() 
    {       
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $process->argument( "foobar" )->argument( "42" );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "foobar 42" . PHP_EOL, $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }

    public function testStdoutOutputRedirection() 
    {       
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $process->argument( "foobar" );
        $process->redirect( pbsSystemProcess::STDOUT, pbsSystemProcess::STDERR );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "foobar" . PHP_EOL, $process->stderrOutput );
    }

    public function testStdoutOutputRedirectionToFile() 
    {       
        $tmpfile = tempnam( sys_get_temp_dir(), "pbs" );
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $process->argument( "foobar" );
        $process->redirect( pbsSystemProcess::STDOUT, $tmpfile );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
        $this->assertEquals( "foobar" . PHP_EOL, file_get_contents( $tmpfile ) );
        unlink( $tmpfile );
    }

    public function testStdoutOutputRedirectionBeforeArgument() 
    {       
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $process->redirect( pbsSystemProcess::STDOUT, pbsSystemProcess::STDERR )
                ->argument( "foobar" );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "foobar" . PHP_EOL, $process->stderrOutput );
    }

    public function testStdoutOutputRedirectionToFileBeforeArgument() 
    {       
        $tmpfile = tempnam( sys_get_temp_dir(), "pbs" );
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $process->redirect( pbsSystemProcess::STDOUT, $tmpfile )
                ->argument( "foobar" );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "", $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
        $this->assertEquals( "foobar" . PHP_EOL, file_get_contents( $tmpfile ) );
        unlink( $tmpfile );
    }

    public function testSimplePipe() 
    {
        $outputProcess = new pbsSystemProcess( 'php tests/bin/cat' );
        $process       = new pbsSystemProcess( 'php tests/bin/echo' );
        $process->argument( 'foobar' )
                ->pipe( $outputProcess );
        $this->assertEquals( $process->execute(), 0 );
        $this->assertEquals( "foobar" . PHP_EOL, $process->stdoutOutput );
        $this->assertEquals( "", $process->stderrOutput );
    }

    public function testRecursivePipe() 
    {
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
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
        if ( self::$win )
        {
            $this->markTestSkipped( 'Test skipped, because Windows does not support evaluation of environment variables.' );
        }

        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $this->assertEquals( 
            $process->argument( '"${environment_test}"', true )
                    ->environment( 
                        array( 'environment_test' => 'foobar' )
                    )
                    ->execute(),
            0
       );
       $this->assertEquals( $process->stdoutOutput, "foobar" . PHP_EOL );
    }

    public function testCustomWorkingDirectory() 
    {
        $process = new pbsSystemProcess(
            ( self::$win ? 'workingDirectoryTest.bat' : './workingDirectoryTest.sh' ) );
        $this->assertEquals( 
            $process->workingDirectory( __DIR__ . '/data' )
                    ->execute(),
            0
        );
        $this->assertEquals( $process->stdoutOutput, "foobar" . PHP_EOL );
    }

    public function testAsyncExecution() 
    {
        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $pipes = $process->argument( 'foobar' )
                         ->execute( true );
        $output = '';
        while( !feof( $pipes[1] ) ) 
        {
            $output .= fread( $pipes[1], 4096 );
        }
        $this->assertEquals( $process->close(), 0 );
        $this->assertEquals( $output, "foobar" . PHP_EOL );
    }

    public function testWriteToStdin() 
    {
        $process = new pbsSystemProcess( 'php tests/bin/cat' );
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
        if ( self::$win )
        {
            $this->markTestSkipped( 'Test skipped, because Windows does not know custom file descriptors.' );
        }

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
        if ( self::$win )
        {
            $this->markTestSkipped( 'Test skipped, because Windows does not know custom file descriptors.' );
        }

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

        $process = new pbsSystemProcess( 'php tests/bin/echo' );
        $pipes = $process->argument( "foobar\nbaz" )
                         ->pipe( $grep )
                         ->execute( true );
        $output = '';
        while( !feof( $pipes[1] ) ) 
        {
            $output .= fread( $pipes[1], 4096 );
        }
        $this->assertEquals( $process->close(), 0 );
        $this->assertEquals( $output, "foobar" . PHP_EOL );
    }

    public function testSignal() 
    {
        if ( self::$win )
        {
            $this->markTestSkipped( 'Test skipped, because Windows signal handling is completely broken.' );
        }

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
        $process = new pbsSystemProcess( 'php' );
        $process->nonZeroExitCodeException = true;
        $process->argument( '-r')->argument( 'exit( 1 );' );
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
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/nonZeroExitCodeOutputTest.' . ( self::$win ? 'bat' : 'sh' ) );
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
        $process = new pbsSystemProcess( __DIR__ . '/data' . '/nonZeroExitCodeOutputTest.' . ( self::$win ? 'bat' : 'sh' ) );
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

        if ( self::$win )
        {
            $this->assertEquals(
                'someCommand "someArgument" "42" 1>&2', (string)$process,
                'Magic __toString conversion did not return expected result.'
            );
        }
        else
        {
            $this->assertEquals(
                "someCommand 'someArgument' '42' 1>&2", (string)$process,
                'Magic __toString conversion did not return expected result.'
            );
        }
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

    public function testPathArgument()
    {
        $process = new pbsSystemProcess( 'php tests/bin/cat' );
        $process->argument( new pbsPathArgument( 'tests/data/workingDirectoryTest.sh' ) );
        $process->execute();

        $this->assertEquals(
            file_get_contents( 'tests/data/workingDirectoryTest.sh' ),
            $process->stdoutOutput
        );
    }
}
