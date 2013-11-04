// +build linux

package main

import (
	"fmt"
	"koding/kites/supervisor/container"
	"net"
	"time"
)

const ContainerOnDuration = 15 * time.Minute

type Info struct {
	Name          string
	IP            net.IP
	ShutdownTimer *time.Timer
}

func NewInfo(name string) *Info {
	return &Info{
		Name:          name,
		ShutdownTimer: time.NewTimer(0),
	}
}

func GetInfo(name string) *Info {
	// var info *Info
	// var found bool
	info, found := containers[name]
	if !found {
		fmt.Println("creating new one")
		info = NewInfo(name)
		containers[name] = info
	} else {
		fmt.Println("using old one")
	}

	return info
}

// StartTimer starts the shutdown timer. After 15 minutes it stops and
// unprepares the container.
func (i *Info) StartTimer() {
	i.ShutdownTimer = time.AfterFunc(ContainerOnDuration, func() {
		fmt.Println("startTimer has been fired")
		c := container.NewContainer(i.Name)
		c.IP = i.IP

		fmt.Printf("startTimer is stopping the container: '%s'\n", c.Name)
		err := c.Stop()
		if err != nil {
			fmt.Printf("ERROR: startTimer could not stop '%s'\n", err)
		}

		fmt.Printf("startTimer is unpreparing the container: '%s'\n", c.Name)
		err = c.Unprepare()
		if err != nil {
			fmt.Printf("ERROR: startTimer could not unprepare '%s'\n", err)
		}
	})
}

// ResetTimer resets the shutdown timer. The timer then begins to counting
// again.
func (i *Info) ResetTimer() {
	fmt.Println("resetting timer")
	i.ShutdownTimer.Reset(ContainerOnDuration)
}
