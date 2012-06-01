<?php
/**
 * systemProcess argument base class
 *
 * This file is part of systemProcess.
 *
 * systemProcess is free software; you can redistribute it and/or modify it
 * under the terms of the Lesser GNU General Public License as published by the
 * Free Software Foundation; version 3 of the License.
 *
 * systemProcess is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the Lesser GNU General Public License
 * for more details.
 *
 * You should have received a copy of the Lesser GNU General Public License
 * along with systemProcess; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * @license http://www.gnu.org/licenses/lgpl-3.0.txt LGPL
 */

/**
 * Argument base class
 *
 * Base class, which should be extended for argument types, which require 
 * special handling.
 * 
 * @version //autogen//
 * @author Kore Nordmann <kore@php.net>
 * @license LGPLv3
 */
abstract class pbsArgument 
{
    /**
     * Raw argument value
     * 
     * @var string
     */
    protected $value;

    /**
     * Construct argument from argument value
     * 
     * @param string $value 
     * @return void
     */
    public function __construct( $value )
    {
        $this->value = $value;
    }

    /**
     * Get prepared argument value
     * 
     * @return string
     */
    abstract public function getPrepared();
}

