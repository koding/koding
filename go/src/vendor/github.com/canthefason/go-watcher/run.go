// Package watcher is a command line tool inspired by fresh (https://github.com/pilu/fresh) and used
// for watching .go file changes, and restarting the app in case of an update/delete/add operation.
// After you installed it, you can run your apps with their default parameters as:
// watcher -c config -p 7000 -h localhost
package watcher

import (
	"log"
	"os/exec"
	"sync"

	"github.com/fatih/color"
)

// Runner listens for the change events and depending on that kills
// the obsolete process, and runs a new one
type Runner struct {
	start chan string
	done  chan struct{}
	cmd   *exec.Cmd

	mu *sync.Mutex
}

// NewRunner creates a new Runner instance and returns its pointer
func NewRunner() *Runner {
	return &Runner{
		start: make(chan string),
		done:  make(chan struct{}),
		mu:    &sync.Mutex{},
	}
}

// Run initializes runner with given parameters.
func (r *Runner) Run(p *Params) {
	for fileName := range r.start {

		color.Green("Running %s...\n", p.Get("run"))

		cmd, err := runCommand(fileName, p.Package...)
		if err != nil {
			log.Printf("Could not run the go binary: %s \n", err)
			r.kill()

			continue
		}

		r.mu.Lock()
		r.cmd = cmd
		removeFile(fileName)
		r.mu.Unlock()

		go func(cmd *exec.Cmd) {
			if err := cmd.Wait(); err != nil {
				log.Printf("process interrupted: %s \n", err)
				r.kill()
			}
		}(r.cmd)
	}
}

// Restart kills the process, removes the old binary and
// restarts the new process
func (r *Runner) restart(fileName string) {
	r.kill()

	r.start <- fileName
}

func (r *Runner) kill() {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.cmd != nil {
		pid := r.cmd.Process.Pid
		log.Printf("Killing PID %d \n", pid)
		r.cmd.Process.Kill()
		r.cmd = nil
	}
}

func (r *Runner) Close() {
	close(r.start)
	r.kill()
	close(r.done)
}

func (r *Runner) Wait() {
	<-r.done
}
