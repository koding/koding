package main

import (
	"fmt"
	"runtime"
	"time"
)

var shouldDebug = false

// TODO: allow filtering via flags: --debug-filter=/Attr/
func debug(t time.Time, keys ...string) {
	if !shouldDebug {
		return
	}

	pc := make([]uintptr, 10)
	runtime.Callers(2, pc)
	f := runtime.FuncForPC(pc[0])

	duration := time.Since(t)
	fmt.Printf("%6v %10s %v\n", duration-(duration%time.Millisecond), f.Name(), keys)
}
