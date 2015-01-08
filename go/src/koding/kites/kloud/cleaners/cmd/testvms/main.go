package main

import (
	"koding/kites/kloud/cleaners/testvms"
	"time"
)

func main() {
	t := testvms.New([]string{"sandbox", "dev"}, time.Hour*24*7)
	t.Process()
}
