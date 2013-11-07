/*
 * concurrent_stress.go
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
	"fmt"
	"github.com/caglar10ur/lxc"
	"math/rand"
	"runtime"
	"strconv"
	"sync"
	"time"
)

func init() {
	runtime.GOMAXPROCS(runtime.NumCPU())
}

func main() {
	var wg sync.WaitGroup

	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func(i int) {
			name := strconv.Itoa(rand.Intn(10))

			z := lxc.NewContainer(name)
			defer lxc.PutContainer(z)

			// sleep for a while to simulate some dummy work
			time.Sleep(time.Millisecond * time.Duration(rand.Intn(500)))

			if z.Defined() {
				if !z.Running() {
					z.SetDaemonize()
					//					fmt.Printf("Starting the container (%s)...\n", name)
					if !z.Start(false, nil) {
						fmt.Printf("Starting the container (%s) failed...\n", name)
					}
				} else {
					//					fmt.Printf("Stopping the container (%s)...\n", name)
					if !z.Stop() {
						fmt.Printf("Stopping the container (%s) failed...\n", name)
					}
				}
			} else {
				if !z.Create("ubuntu", []string{"amd64", "quantal"}) {
					fmt.Printf("Creating the container (%s) failed...\n", name)
				}
			}
			wg.Done()
		}(i)
	}
	wg.Wait()
}
