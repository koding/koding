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

	p := make([]uintptr, 10)
	runtime.Callers(2, p)
	f := runtime.FuncForPC(p[0])
	d := time.Since(t)

	fmt.Printf("%6v %10s %v\n", d-(d%time.Millisecond), f.Name(), keys)
}
