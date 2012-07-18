<?php
/**
 * arbit test runner
 *
 * This file is part of arbit.
 *
 * arbit is free software; you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation; version 3 of the License.
 *
 * arbit is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
 * more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with arbit; if not, write to the Free Software Foundation, Inc., 51
 * Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * @package Core
 * @version $Revision$
 * @license http://www.gnu.org/licenses/lgpl-3.0.txt LGPL
 */

class arbitTextUiResultPrinter extends PHPUnit_TextUI_ResultPrinter
{
    /**
     * Current column position in output
     * 
     * @var int
     */
    protected $column = 0;

    /**
     * Number of tests already finished
     * 
     * @var int
     */
    protected $testsRun = 0;

    /**
     * Stack of command indentation
     * 
     * @var array
     */
    protected $indentation = array();

    /**
     * Number of tests already run in current suite
     * 
     * @var array
     */
    protected $suiteTestsRun = array( 0 );

    /**
     * Number of tests already run in current suite
     * 
     * @var array
     */
    protected $testSuiteSize = array();

    /**
     * Event type, when a data provider has been started
     */
    const DATA_PROVIDER_START = 100;

    /**
     * Event type, when a data provider has been finished
     */
    const DATA_PROVIDER_END   = 101;

    /**
     * @param  PHPUnit_Framework_TestResult  $result
     * @access protected
     */
    protected function printFooter(PHPUnit_Framework_TestResult $result)
    {
        if ($result->wasSuccessful() &&
            $result->allCompletlyImplemented() &&
            $result->noneSkipped())
        {
            $this->write(
              "\n\033[1;37;42m" .
              ( $result = sprintf(
                "OK (%d test%s, %d assertion%s)",

                count($result),
                (count($result) == 1) ? '' : 's',
                $this->numAssertions,
                ($this->numAssertions == 1) ? '' : 's'
              ) ) .
              str_repeat( ' ', 80 - strlen( $result ) ) .
              "\033[0m\n"
            );
        }
        elseif ((!$result->allCompletlyImplemented() ||
                  !$result->noneSkipped())&&
                 $result->wasSuccessful())
        {
            $this->write(
              "\n\033[1;37;43mOk, but incomplete or skipped tests!                                            \033[0m\n" . 
                sprintf( 
                    "Tests: %d, Assertions: %d%s%s.\n",

                    count($result),
                    $this->numAssertions,
                    $this->getCountString($result->notImplementedCount(), 'Incomplete'),
                    $this->getCountString($result->skippedCount(), 'Skipped')
                )
            );
        }
        else
        {
            $this->write(
              sprintf(
                "\n\033[1;37;41mFailures                                                                        \033[m\n" .
                "Tests: %d, Assertions: %s%s%s%s.\n",
                count($result),
                $this->numAssertions,
                $this->getCountString($result->failureCount(), 'Failures'),
                $this->getCountString($result->errorCount(), 'Errors'),
                $this->getCountString($result->notImplementedCount(), 'Incomplete'),
                $this->getCountString($result->skippedCount(), 'Skipped')
              )
            );
        }
    }

    /**
     * An error occurred.
     *
     * @param  PHPUnit_Framework_Test $test
     * @param  Exception              $e
     * @param  float                  $time
     * @access public
     */
    public function addError(PHPUnit_Framework_Test $test, Exception $e, $time)
    {
        $this->writeProgress( "\033[1;31m✘\033[0m" );
        $this->lastTestFailed = true;
    }

    /**
     * A failure occurred.
     *
     * @param  PHPUnit_Framework_Test                 $test
     * @param  PHPUnit_Framework_AssertionFailedError $e
     * @param  float                                  $time
     * @access public
     */
    public function addFailure(PHPUnit_Framework_Test $test, PHPUnit_Framework_AssertionFailedError $e, $time)
    {
        $this->writeProgress( "\033[0;31m✗\033[0m" );
        $this->lastTestFailed = true;
    }

    /**
     * Incomplete test.
     *
     * @param  PHPUnit_Framework_Test $test
     * @param  Exception              $e
     * @param  float                  $time
     * @access public
     */
    public function addIncompleteTest(PHPUnit_Framework_Test $test, Exception $e, $time)
    {
        $this->writeProgress( "\033[0;33m◔\033[0m" );
        $this->lastTestFailed = true;
    }

    /**
     * Skipped test.
     *
     * @param  PHPUnit_Framework_Test $test
     * @param  Exception              $e
     * @param  float                  $time
     * @access public
     * @since  Method available since Release 3.0.0
     */
    public function addSkippedTest(PHPUnit_Framework_Test $test, Exception $e, $time)
    {
        $this->writeProgress( "\033[0;34m➔\033[0m" );
        $this->lastTestFailed = true;
    }

    /**
     * A test started.
     *
     * @param  PHPUnit_Framework_Test $test
     */
    public function startTest(PHPUnit_Framework_Test $test)
    {
        if ( ( $this->lastEvent === self::DATA_PROVIDER_END ) &&
             ( end( $this->suiteTestsRun ) < end( $this->testSuiteSize ) ) )
        {
            echo "\n", str_repeat( '  ', count( $this->testSuiteSize ) - 1 ), '↳ ';
            $this->column = count( $this->testSuiteSize ) * 2;
        }

        parent::startTest( $test );
    }

    /**
     * A test ended.
     *
     * @param  PHPUnit_Framework_Test $test
     * @param  float                  $time
     * @access public
     */
    public function endTest(PHPUnit_Framework_Test $test, $time)
    {
        if (!$this->lastTestFailed) {
            $this->writeProgress( "\033[1;32m✓\033[0m" );
        }

        if ($test instanceof PHPUnit_Framework_TestCase) {
            $this->numAssertions += $test->getNumAssertions();
        }

        $this->lastEvent = self::EVENT_TEST_END;
        $this->lastTestFailed = false;
        $this->column++;
        $this->testsRun++;
        $this->suiteTestsRun[count( $this->suiteTestsRun ) - 1]++;

        // Wrap tests, if they exceed the column width
        if ( $this->column >= 72 )
        {
            echo " ↩\n", str_repeat( ' ', ( $this->column = end( $this->indentation ) ) - 2 ), '↳ ';
        }
    }

    /**
     * A testsuite started.
     *
     * @param  PHPUnit_Framework_TestSuite $suite
     * @access public
     * @since  Method available since Release 2.2.0
     */
    public function startTestSuite(PHPUnit_Framework_TestSuite $suite)
    {
        $name = $suite->getName();
        $isDataProvider = strpos( $suite->getName(), '::' ) !== false;

        if (empty($name)) {
            $name = 'Test Suite';
        }

        $name = preg_replace( '(^.*::(.*?)$)', '\\1', $name );

        $this->write(
          $title = sprintf(
            "%s%s• %s: ",
            "\n",
            // $this->lastEvent == self::EVENT_TESTSUITE_START || $this->lastEvent == self::EVENT_TEST_END ? "\n" : '',
            str_repeat( '  ', count( $this->testSuiteSize ) ),
            $name
          )
        );

        array_push( $this->testSuiteSize, count( $suite ) );
        array_push( $this->indentation, $this->column = strlen( $title ) - 3 );
        array_push( $this->suiteTestsRun, 0 );

        $this->lastEvent = ( $isDataProvider ? self::DATA_PROVIDER_START : self::EVENT_TESTSUITE_START );
    }

    /**
     * A testsuite ended.
     *
     * @param  PHPUnit_Framework_TestSuite $suite
     * @access public
     * @since  Method available since Release 2.2.0
     */
    public function endTestSuite(PHPUnit_Framework_TestSuite $suite)
    {
        $isDataProvider = strpos( $suite->getName(), '::' ) !== false;

        if ( $this->lastEvent === self::EVENT_TEST_END )
        {
            echo ( ( $this->column < 72 ) ? str_repeat( ' ', 73 - $this->column ) : ' ' );
            printf( "[%3d%%]", $this->testsRun / $this->testSuiteSize[0] * 100 );
        }

        array_pop( $this->testSuiteSize );
        array_pop( $this->indentation );
        $run = array_pop( $this->suiteTestsRun );
        $this->suiteTestsRun[count( $this->suiteTestsRun ) - 1] += $run;

        $this->lastEvent = ( $isDataProvider ? self::DATA_PROVIDER_END : self::EVENT_TESTSUITE_END );
    }

    /**
     * @param  string $progress
     * @access protected
     */
    protected function writeProgress( $progress )
    {
        $this->write( $progress );
    }
}

