package fuseklient

import (
	"fmt"
	"runtime"
	"strings"
	"time"
)

var DebugEnabled = false

func debug(t time.Time, format string, values ...interface{}) {
	if !DebugEnabled {
		return
	}

	p := make([]uintptr, 10)
	runtime.Callers(2, p)

	f := runtime.FuncForPC(p[0])
	d := time.Since(t)

	var m string
	m = strings.TrimLeft(f.Name(), "github.com/koding/fuseklient/fs")

	format = "%6v %10s " + format + "\n"

	args := []interface{}{(d - (d % time.Millisecond)), m}
	args = append(args, values...)

	fmt.Printf(format, args...)
}
