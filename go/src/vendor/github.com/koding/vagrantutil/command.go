package vagrantutil

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"sync"

	"github.com/koding/logging"
)

var env = append(os.Environ(), "VAGRANT_CHECKPOINT_DISABLE=1")

type command struct {
	log logging.Logger
	cwd string

	onSuccess func()
	onFailure func(err error)

	ignoreErr  func(err error) bool
	errIgnored bool

	cmd *exec.Cmd
}

func newCommand(cwd string, log logging.Logger) *command {
	cmd := &command{
		cwd: cwd,
	}

	if log != nil {
		cmd.log = log.New(cwd)
	}

	return cmd
}

func (cmd *command) init(args []string) {
	cmd.cmd = exec.Command("vagrant", args...)
	cmd.cmd.Dir = cmd.cwd
	cmd.cmd.Env = env

	cmd.debugf("%s: executing: %v", cmd.cwd, cmd.cmd.Args)
}

func (cmd *command) run(args ...string) (string, error) {
	cmd.init(args)

	out, err := cmd.cmd.CombinedOutput()
	if err != nil && len(out) != 0 {
		err = fmt.Errorf("%s: %s", err, out)
	}

	if e := cmd.checkError(err); e != nil {
		return "", cmd.done(e)
	}

	s := string(out)

	cmd.debugf("execution of %v was successful: %s", cmd.cmd.Args, s)

	return s, cmd.done(nil)

}

// start starts the command and sends back both the stdout and stderr to
// the returned channel. Any error happened during the streaming is passed to
// the Error field.
func (cmd *command) start(args ...string) (ch <-chan *CommandOutput, err error) {
	cmd.init(args)

	stdoutPipe, err := cmd.cmd.StdoutPipe()
	if err != nil {
		return nil, cmd.done(err)
	}

	stderrPipe, err := cmd.cmd.StderrPipe()
	if err != nil {
		return nil, cmd.done(err)
	}

	if err := cmd.cmd.Start(); err != nil {
		return nil, cmd.done(err)
	}

	var wg sync.WaitGroup
	wg.Add(2)
	out := make(chan *CommandOutput)

	output := func(r io.Reader) {
		scanner := bufio.NewScanner(r)
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line == "" {
				continue // ignore excessive whitespace
			}

			cmd.debugf("%s", line)
			cmd.checkError(errors.New(line))

			out <- &CommandOutput{Line: line}
		}

		cmd.reportError(out, scanner.Err())
		wg.Done()
	}

	go output(stdoutPipe)
	go output(stderrPipe)

	go func() {
		wg.Wait()

		err := cmd.reportError(out, cmd.cmd.Wait())

		close(out)
		cmd.done(err)
	}()

	return out, nil
}

func (cmd *command) done(err error) error {
	if e := cmd.checkError(err); e != nil {

		cmd.debugf("execution of %v failed: %s", cmd.cmd.Args, e)

		if cmd.onFailure != nil {
			cmd.onFailure(e)
		}

		return e
	}

	if cmd.onSuccess != nil {
		cmd.onSuccess()
	}

	return nil
}

func (cmd *command) checkError(err error) error {
	if err == nil {
		return nil
	}

	if cmd.errIgnored || cmd.ignoreErr != nil && cmd.ignoreErr(err) {
		cmd.errIgnored = true
		return nil
	}

	return err
}

func (cmd *command) reportError(out chan<- *CommandOutput, err error) error {
	if e := cmd.checkError(err); e != nil {
		cmd.debugf("reporting error for %v: %s (%t)", cmd.cmd.Args, err, cmd.errIgnored)
		out <- &CommandOutput{Error: err}

		return e
	}

	return nil
}

func (cmd *command) debugf(format string, args ...interface{}) {
	if cmd.log != nil {
		cmd.log.Debug(format, args...)
	}
}
