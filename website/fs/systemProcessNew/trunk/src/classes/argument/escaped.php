<?php
/**
 * systemProcess escaped argument class
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
 * Escaped argument
 *
 * Argument, which values are prepared for sane usage in calls, disabling 
 * injection.
 * 
 * @version //autogen//
 * @author Kore Nordmann <kore@php.net>
 * @license LGPLv3
 */
class pbsEscapedArgument extends pbsArgument 
{
    /**
     * Get prepared argument value
     * 
     * @return string
     */
    public function getPrepared()
    {
        if ( strtoupper( substr( PHP_OS, 0, 3 ) ) === 'WIN' )
        {
            // escapeshellarg() is entirely incapeable of escaping shell args 
            // on windows - it strips out % and ", f.e. We do this ourselves:
            //
            // Let's hope there are not too many cmd injection vulnaribilities. 
            // But since the shell does not parse the arguments anyways, but 
            // only the target tool, it shouldn't hurt too much.
            $this->value = str_replace( '%', '"%"', $this->value );
            $this->value = preg_replace( '(\\\\$)', '\\\\\\\\', $this->value );

            return '"' . $this->value . '"';
        }

        return escapeshellarg( $this->value );
    }
}

