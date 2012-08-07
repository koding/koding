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
 * @version $Revision: 11 $
 * @license http://www.gnu.org/licenses/lgpl-3.0.txt LGPL
 */

define('PHPUnit_MAIN_METHOD', 'arbitTextUiCommand::main');
require 'PHPUnit/TextUI/Command.php';

// Custom printer
require dirname( __FILE__ ) . '/printer.php';

class arbitTextUiCommand extends PHPUnit_TextUI_Command
{
    /**
     * @param boolean $exit
     */
    public static function main($exit = TRUE)
    {
        $command = new static();
        $command->run($_SERVER['argv'], $exit);
    }

    /**
     * @param array $argv
     * @param boolean $exit
     */
    public function run( array $argv, $exit = true )
    {
        $this->arguments['printer'] = new arbitTextUiResultPrinter();
        return parent::run( $argv, $exit );
    }
}

