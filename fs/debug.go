package fs

import (
	"fmt"
	"runtime"
	"strings"
	"time"
)

func debug(t time.Time, keys ...string) {
	p := make([]uintptr, 10)
	runtime.Callers(2, p)

	f := runtime.FuncForPC(p[0])
	d := time.Since(t)

	var m string
	m = strings.TrimLeft(f.Name(), "github.com/koding/fuseklient/fs")
	m = strings.TrimLeft(m, "(*KodingNetworkFS).")

	fmt.Printf("%6v %10s %v\n", d-(d%time.Millisecond), m, keys)
}
