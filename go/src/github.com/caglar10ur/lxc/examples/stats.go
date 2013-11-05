/*
 * stats.go
 *
 * Copyright © 2013, S.Çağlar Onur
 *
 * Authors:
 * S.Çağlar Onur <caglar@10ur.org>
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2, as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

package main

import (
	"flag"
	"fmt"
	"github.com/caglar10ur/lxc"
)

var (
	name string
)

func init() {
	flag.StringVar(&name, "name", "rubik", "Name of the container")
	flag.Parse()
}

func main() {
	c := lxc.NewContainer(name)
	defer lxc.PutContainer(c)

	if c.Running() {
		// mem
		mem_used, _ := c.MemoryUsageInBytes()
		fmt.Printf("mem_used: %s\n", mem_used)

		mem_limit, _ := c.MemoryLimitInBytes()
		fmt.Printf("mem_limit: %s\n", mem_limit)

		// swap
		swap_used, _ := c.SwapUsageInBytes()
		fmt.Printf("memsw_used: %s\n", swap_used)

		swap_limit, _ := c.SwapLimitInBytes()
		fmt.Printf("memsw_used: %s\n", swap_limit)
	} else {
		fmt.Printf("Container is not running...\n")
	}
}
