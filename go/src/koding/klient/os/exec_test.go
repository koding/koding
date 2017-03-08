package os_test

import (
	"reflect"
	"testing"

	"koding/klient/os"

	"github.com/koding/kite"
)

func TestExec(t *testing.T) {
	env := map[string]string{
		"TESTHELPER_FOO":  "bar",
		"TESTHELPER_HOME": "/home/rjeczalik",
		"TESTHELPER_PATH": "/usr/bin:/bin:/sbin",
	}

	cases := map[string]struct {
		req    *os.ExecRequest
		stdout []string
		stderr []string
		exit   int
	}{
		"echo stdout": {
			&os.ExecRequest{
				Cmd:  "echo",
				Args: []string{"-stdout", "Hello World!"},
			},
			[]string{"Hello World!"},
			nil,
			0,
		},
		"echo stderr": {
			&os.ExecRequest{
				Cmd:  "echo",
				Args: []string{"-stderr", "-exit", "2", "Hello World!"},
			},
			nil,
			[]string{"Hello World!"},
			2,
		},
		"echo stdout + stderr": {
			&os.ExecRequest{
				Cmd:  "echo",
				Args: []string{"-stdout", "-stderr", "-exit", "1", "Hello World!"},
			},
			[]string{"Hello World!"},
			[]string{"Hello World!"},
			1,
		},
		"env": {
			&os.ExecRequest{
				Cmd:  "env",
				Envs: env,
			},
			os.Environ(env).Encode(nil),
			nil,
			0,
		},
		"tee": {
			&os.ExecRequest{
				Cmd:   "tee",
				Stdin: []byte("a\nb\nc\nd"),
			},
			[]string{"a", "b", "c", "d"},
			nil,
			0,
		},
	}

	h := os.NewHandler()

	s, c, err := serve(map[string]kite.HandlerFunc{
		"os.exec": h.Exec,
	})
	defer s.Close()

	if err != nil {
		t.Fatalf("serve()=%s", err)
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			var resp os.ExecResponse
			req := makereq(cas.req)
			rec := record(req)

			if err := call(c, "os.exec", timeout, req, &resp); err != nil {
				t.Fatalf("call()=%s", err)
			}

			if resp.PID == 0 {
				t.Fatal("want resp.Pid != 0")
			}

			if err := rec.wait(timeout); err != nil {
				t.Fatalf("wait()=%s", err)
			}

			if stdout := rec.Stdout(); !reflect.DeepEqual(stdout, cas.stdout) {
				t.Fatalf("got %v, want %v", stdout, cas.stdout)
			}

			if stderr := rec.Stderr(); !reflect.DeepEqual(stderr, cas.stderr) {
				t.Fatalf("got %v, want %v", stderr, cas.stderr)
			}

			if exit := rec.Exit(); exit != cas.exit {
				t.Fatalf("got %d, want %d", exit, cas.exit)
			}
		})
	}
}

func TestKill(t *testing.T) {
	h := os.NewHandler()

	s, c, err := serve(map[string]kite.HandlerFunc{
		"os.exec": h.Exec,
		"os.kill": h.Kill,
	})
	defer s.Close()

	if err != nil {
		t.Fatalf("serve()=%s", err)
	}

	var resp os.ExecResponse
	req := makereq(&os.ExecRequest{
		Cmd:  "sleep",
		Args: []string{"15s"},
	})
	rec := record(req)

	if err := call(c, "os.exec", timeout, req, &resp); err != nil {
		t.Fatalf("call()=%s", err)
	}

	if resp.PID == 0 {
		t.Fatal("want resp.Pid != 0")
	}

	if err := call(c, "os.kill", timeout, &os.KillRequest{PID: resp.PID}, nil); err != nil {
		t.Fatalf("call()=%s", err)
	}

	if err := rec.wait(timeout); err != nil {
		t.Fatalf("wait()=%s", err)
	}

	if stdout := rec.Stdout(); len(stdout) != 0 {
		t.Fatalf("got %v, want it to be empty", stdout)
	}

	if stderr := rec.Stderr(); len(stderr) != 0 {
		t.Fatalf("got %v, want it to be empty", stderr)
	}

	if exit := rec.Exit(); exit != -1 {
		t.Fatalf("got %d, want %d", exit, -1)
	}
}
