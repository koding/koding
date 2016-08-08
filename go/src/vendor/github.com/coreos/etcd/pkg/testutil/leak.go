// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package testutil

import (
	"fmt"
	"net/http"
	"os"
	"runtime"
	"sort"
	"strings"
	"testing"
	"time"
)

/*
CheckLeakedGoroutine verifies tests do not leave any leaky
goroutines. It returns true when there are goroutines still
running(leaking) after all tests.

	import "github.com/coreos/etcd/pkg/testutil"

	func TestMain(m *testing.M) {
		v := m.Run()
		if v == 0 && testutil.CheckLeakedGoroutine() {
			os.Exit(1)
		}
		os.Exit(v)
	}

	func TestSample(t *testing.T) {
		defer testutil.AfterTest(t)
		...
	}

*/
func CheckLeakedGoroutine() bool {
	if testing.Short() {
		// not counting goroutines for leakage in -short mode
		return false
	}
	gs := interestingGoroutines()

	n := 0
	stackCount := make(map[string]int)
	for _, g := range gs {
		stackCount[g]++
		n++
	}

	if n == 0 {
		return false
	}
	fmt.Fprintf(os.Stderr, "Too many goroutines running after all test(s).\n")
	for stack, count := range stackCount {
		fmt.Fprintf(os.Stderr, "%d instances of:\n%s\n", count, stack)
	}
	return true
}

func AfterTest(t *testing.T) {
	http.DefaultTransport.(*http.Transport).CloseIdleConnections()
	if testing.Short() {
		return
	}
	var bad string
	badSubstring := map[string]string{
		").writeLoop(":                                 "a Transport",
		"created by net/http/httptest.(*Server).Start": "an httptest.Server",
		"timeoutHandler":                               "a TimeoutHandler",
		"net.(*netFD).connect(":                        "a timing out dial",
		").noteClientGone(":                            "a closenotifier sender",
	}

	// readLoop was buggy before go1.5:
	// https://github.com/golang/go/issues/10457
	if getAtLeastGo15() {
		badSubstring[").readLoop("] = "a Transport"
	}

	var stacks string
	for i := 0; i < 6; i++ {
		bad = ""
		stacks = strings.Join(interestingGoroutines(), "\n\n")
		for substr, what := range badSubstring {
			if strings.Contains(stacks, substr) {
				bad = what
			}
		}
		if bad == "" {
			return
		}
		// Bad stuff found, but goroutines might just still be
		// shutting down, so give it some time.
		time.Sleep(50 * time.Millisecond)
	}
	t.Errorf("Test appears to have leaked %s:\n%s", bad, stacks)
}

func interestingGoroutines() (gs []string) {
	buf := make([]byte, 2<<20)
	buf = buf[:runtime.Stack(buf, true)]
	for _, g := range strings.Split(string(buf), "\n\n") {
		sl := strings.SplitN(g, "\n", 2)
		if len(sl) != 2 {
			continue
		}
		stack := strings.TrimSpace(sl[1])
		if stack == "" ||
			strings.Contains(stack, "created by testing.RunTests") ||
			strings.Contains(stack, "testing.Main(") ||
			strings.Contains(stack, "runtime.goexit") ||
			strings.Contains(stack, "github.com/coreos/etcd/pkg/testutil.interestingGoroutines") ||
			strings.Contains(stack, "github.com/coreos/etcd/pkg/logutil.(*MergeLogger).outputLoop") ||
			strings.Contains(stack, "github.com/golang/glog.(*loggingT).flushDaemon") ||
			strings.Contains(stack, "created by runtime.gc") ||
			strings.Contains(stack, "runtime.MHeap_Scavenger") {
			continue
		}
		gs = append(gs, stack)
	}
	sort.Strings(gs)
	return
}

// getAtLeastGo15 returns true if the runtime has go1.5+.
func getAtLeastGo15() bool {
	var major, minor int
	var discard string
	i, err := fmt.Sscanf(runtime.Version(), "go%d.%d%s", &major, &minor, &discard)
	return (err == nil && i == 3 && (major > 1 || major == 1 && minor >= 5))
}
