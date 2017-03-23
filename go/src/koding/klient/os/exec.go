package os

import (
	"bufio"
	"bytes"
	"errors"
	"io"
	"os"
	"os/exec"
	"sync"
	"syscall"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

var environ = NewEnviron(os.Environ())

// DefaultHandler is a handler used by Exec and Kill methods.
var DefaultHandler = NewHandler()

// ExecRequest represents a request value for the "os.exec" kite method.
type ExecRequest struct {
	Cmd     string            `json:"cmd"`     // a binary to execute which must be in $PATH on remote; required
	Args    []string          `json:"args"`    // command line arguments for the command
	Envs    map[string]string `json:"envs"`    // environmental variables that are merged with the klient ones on the remote side
	WorkDir string            `json:"workDir"` // working directory in which
	Stdin   []byte            `json:"stdin"`   // standard input of the command
	Stdout  dnode.Function    `json:"stdout"`  // func(line string): if not nil, called on each stdout line produced by the command
	Stderr  dnode.Function    `json:"stderr"`  // func(line string): if not nil, called on each stderr line produced by the command
	Exit    dnode.Function    `json:"exit"`    // func(code int): if not nil, called upon command completion with its exit code
}

// Valid implements the stack.Validator interface.
func (r *ExecRequest) Valid() error {
	if r.Cmd == "" {
		return errors.New("invalid empty command")
	}
	return nil
}

// ExecResponse represents a response value for the "os.exec" kite method.
type ExecResponse struct {
	PID int `json:"pid"` // pid of the started process
}

// KillRequest represents a request value for the "os.kill" kite method.
type KillRequest struct {
	PID int `json:"pid"`
}

// Valid implements the stack.Validator interface.
func (r *KillRequest) Valid() error {
	if r.PID == 0 {
		return errors.New("invalid zero pid")
	}
	return nil
}

// KillResponse represents a response value for the "os.kill" kite method.
type KillResponse struct{}

// Handler implements kite handlers for "os.kill" and "os.exec" methods.
type Handler struct {
	mu   sync.Mutex
	cmds map[int]*exec.Cmd
}

// NewHandler gives
func NewHandler() *Handler {
	return &Handler{
		cmds: make(map[int]*exec.Cmd),
	}
}

// Exec is a kite handler for "os.exec" method.
//
// The request value is exepected to be of *ExecRequest type.
func (h *Handler) Exec(r *kite.Request) (interface{}, error) {
	var req ExecRequest

	if r.Args != nil {
		if err := r.Args.One().Unmarshal(&req); err != nil {
			return nil, err
		}
	}

	if err := req.Valid(); err != nil {
		return nil, newError(err)
	}

	resp, err := h.exec(&req)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (h *Handler) exec(r *ExecRequest) (*ExecResponse, error) {
	rcmd, err := exec.LookPath(r.Cmd)
	if err != nil {
		return nil, err // early fail if r.Cmd is not in $PATH
	}

	cmd := exec.Command(rcmd, r.Args...)
	cmd.Dir = r.WorkDir

	if len(r.Envs) != 0 {
		cmd.Env = environ.Encode(r.Envs)
	}

	if len(r.Stdin) != 0 {
		cmd.Stdin = bytes.NewReader(r.Stdin)
	}

	// wg is used to ensure eventuall Exit callback
	// is called after streaming stdout/stderr is done
	// server-side.
	var wg sync.WaitGroup

	if r.Stdout.IsValid() {
		cmd.Stdout = pipe(r.Stdout, &wg)
	}

	if r.Stderr.IsValid() {
		cmd.Stderr = pipe(r.Stderr, &wg)
	}

	if err = cmd.Start(); err != nil {
		stop(cmd.Stdout, cmd.Stderr)
		return nil, err
	}

	h.mu.Lock()
	h.cmds[cmd.Process.Pid] = cmd
	h.mu.Unlock()

	go func() {
		err := cmd.Wait()

		h.mu.Lock()
		delete(h.cmds, cmd.Process.Pid)
		h.mu.Unlock()

		stop(cmd.Stdout, cmd.Stderr)
		wg.Wait()

		if r.Exit.IsValid() {
			code := 0

			if err != nil {
				code = -1
			}

			if e, ok := err.(*exec.ExitError); ok {
				if ws, ok := e.Sys().(syscall.WaitStatus); ok {
					code = ws.ExitStatus()
				}
			}

			r.Exit.Call(code)
		}
	}()

	return &ExecResponse{
		PID: cmd.Process.Pid,
	}, nil
}

// Kill is a kite handler for "os.kill" method.
//
// The request value is exepected to be of *KillRequest type.
func (h *Handler) Kill(r *kite.Request) (interface{}, error) {
	var req KillRequest

	if r.Args != nil {
		if err := r.Args.One().Unmarshal(&req); err != nil {
			return nil, err
		}
	}

	if err := req.Valid(); err != nil {
		return nil, newError(err)
	}

	resp, err := h.kill(&req)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (h *Handler) kill(r *KillRequest) (*KillResponse, error) {
	h.mu.Lock()
	cmd, ok := h.cmds[r.PID]
	delete(h.cmds, r.PID)
	h.mu.Unlock()

	if !ok {
		return nil, errors.New("pid not found")
	}

	if err := cmd.Process.Kill(); err != nil {
		return nil, err
	}

	return &KillResponse{}, nil
}

func Exec(r *kite.Request) (interface{}, error) { return DefaultHandler.Exec(r) }
func Kill(r *kite.Request) (interface{}, error) { return DefaultHandler.Kill(r) }

func newError(err error) error {
	if e, ok := err.(*kite.Error); ok {
		return e
	}
	return &kite.Error{
		Type:    "klient/os",
		Message: err.Error(),
	}
}

func pipe(cb dnode.Function, wg *sync.WaitGroup) io.Writer {
	wg.Add(1)

	r, w := io.Pipe()

	go func() {
		s := bufio.NewScanner(r)

		for s.Scan() {
			cb.Call(s.Text())
		}

		r.Close()
		wg.Done()
	}()

	return w
}

func stop(w ...io.Writer) {
	for _, w := range w {
		if c, ok := w.(io.Closer); ok {
			c.Close()
		}
	}
}
