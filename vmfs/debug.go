package vmfs

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
	m := strings.TrimLeft(f.Name(), "github.com/koding/fuseklient/vmfs.")
	d := time.Since(t)

	fmt.Printf("%6v %10s %v\n", d-(d%time.Millisecond), m, keys)
}
