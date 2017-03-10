package os_test

import (
	"flag"
	"fmt"
	"io/ioutil"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	kos "koding/klient/os"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

const timeout = 5 * time.Second

func die(v ...interface{}) {
	fmt.Fprintln(os.Stderr, v...)
	os.Exit(1)
}

// TestCommandHelper is used by TestExec / TestKill tests to
// execute test code as an external process.
func TestCommandHelper(t *testing.T) {
	if os.Getenv("GO_TEST_COMMAND_HELPER") != "1" {
		return
	}

	cmd := ""
	f := flag.NewFlagSet("helper", flag.ExitOnError)
	exit := f.Int("exit", 0, "")
	stdout := f.Bool("stdout", false, "")
	stderr := f.Bool("stderr", false, "")

	for i, arg := range os.Args {
		if arg == "--" {
			cmd = os.Args[i+1]

			args := os.Args[i+2:]

			if err := f.Parse(args); err != nil {
				die("error: parsing flags:", err)
			}

			break
		}
	}

	write := func(v ...interface{}) {
		if *stderr {
			fmt.Fprint(os.Stderr, v...)
		}

		if !*stderr || *stdout {
			fmt.Print(v...)
		}
	}

	defer os.Exit(*exit)

	switch cmd {
	case "sleep":
		d, err := time.ParseDuration(f.Arg(0))
		if err != nil {
			die(err)
		}
		time.Sleep(d)
		write("awake")
	case "echo":
		write(strings.Join(f.Args(), " "))
	case "tee":
		p, err := ioutil.ReadAll(os.Stdin)
		if err != nil {
			die(err)
		}
		write(string(p))
	case "env":
		envs := kos.NewEnviron(os.Environ())

		// Print those envs only that begin with "TESTHELPER_".
		for k := range envs {
			if !strings.HasPrefix(k, "TESTHELPER_") {
				delete(envs, k)
			}
		}

		write(strings.Join(envs.Encode(nil), "\n"))
	case "":
		die("error: missing command")
	default:
		die("error: unknown command:", cmd)
	}
}

func call(c *kite.Client, method string, timeout time.Duration, req, resp interface{}) error {
	r, err := c.TellWithTimeout(method, timeout, req)
	if err != nil {
		return err
	}

	if resp != nil {
		if err := r.Unmarshal(resp); err != nil {
			return err
		}
	}

	return nil
}

func serve(handlers map[string]kite.HandlerFunc) (*httptest.Server, *kite.Client, error) {
	s := kite.New("test-server", "0.0.0")
	s.Config.DisableAuthentication = true

	for method, handler := range handlers {
		s.HandleFunc(method, handler)
	}

	ts := httptest.NewServer(s)

	c := kite.New("c", "0.0.0").NewClient(fmt.Sprintf("%s/kite", ts.URL))

	if err := c.DialTimeout(timeout); err != nil {
		return nil, nil, err
	}

	return ts, c, nil
}

// makereq enriches the Cmd and Args arguments of the given r request,
// with a values required to run TestCommandHelper.
func makereq(r *kos.ExecRequest) *kos.ExecRequest {
	rCopy := *r

	if rCopy.Envs != nil {
		rCopy.Envs = make(map[string]string, len(r.Envs))
		for k, v := range r.Envs {
			rCopy.Envs[k] = v
		}
	}

	if rCopy.Envs == nil {
		rCopy.Envs = make(map[string]string)
	}

	rCopy.Envs["GO_TEST_COMMAND_HELPER"] = "1"
	rCopy.Cmd = os.Args[0]
	rCopy.Args = []string{"-test.run", "TestCommandHelper", "--", r.Cmd}

	if r.Args != nil {
		rCopy.Args = append(rCopy.Args, r.Args...)
	}

	return &rCopy
}

// execRecorder is a mock used to spy on stdout, stderr and exit code
// of a command process started by a "os.exec" method.
type execRecorder struct {
	mu sync.Mutex

	stdout []string
	stderr []string
	exit   int

	Done chan struct{}
}

// record enriches the Stdout / Stderr / Exit callbacks of the give r request,
// building a dnode functions the persist a streamed output and exit code
// of a command.
func record(r *kos.ExecRequest) *execRecorder {
	rec := &execRecorder{
		Done: make(chan struct{}),
	}

	r.Stdout = dnode.Callback(func(r *dnode.Partial) {
		s := r.One().MustString()

		rec.mu.Lock()
		rec.stdout = append(rec.stdout, s)
		rec.mu.Unlock()
	})

	r.Stderr = dnode.Callback(func(r *dnode.Partial) {
		s := r.One().MustString()

		rec.mu.Lock()
		rec.stderr = append(rec.stderr, s)
		rec.mu.Unlock()
	})

	r.Exit = dnode.Callback(func(r *dnode.Partial) {
		var n int
		r.One().MustUnmarshal(&n)

		rec.mu.Lock()
		rec.exit = n
		rec.mu.Unlock()

		close(rec.Done)
	})

	return rec
}

// Stdout gives a copy of stdout lines streamed from a command.
func (rec *execRecorder) Stdout() []string {
	rec.mu.Lock()
	defer rec.mu.Unlock()

	if rec.stdout == nil {
		return nil
	}

	stdout := make([]string, len(rec.stdout))
	copy(stdout, rec.stdout)
	return stdout
}

// Stderr gives a copy of stderr lines streamed from a command.
func (rec *execRecorder) Stderr() []string {
	rec.mu.Lock()
	defer rec.mu.Unlock()

	if rec.stderr == nil {
		return nil
	}

	stderr := make([]string, len(rec.stderr))
	copy(stderr, rec.stderr)
	return stderr
}

// Exit gives a command's exit code.
func (rec *execRecorder) Exit() int {
	rec.mu.Lock()
	defer rec.mu.Unlock()

	return rec.exit
}

func (rec *execRecorder) wait(timeout time.Duration) error {
	select {
	case <-rec.Done:
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("wait timed out after %s", timeout)
	}
}
