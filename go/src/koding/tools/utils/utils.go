package utils

import (
	"fmt"
	"koding/tools/log"
	"math/rand"
	"os"
	"runtime"
	"time"
)

func DefaultStartup(facility string, needRoot bool) {
	runtime.GOMAXPROCS(runtime.NumCPU())
	rand.Seed(time.Now().UnixNano())
	log.Facility = fmt.Sprintf("$s %d", facility, os.Getpid())

	if needRoot && os.Getuid() != 0 {
		panic("Must be run as root.")
	}
}
