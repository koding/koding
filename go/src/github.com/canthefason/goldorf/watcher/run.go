package watcher

import (
	"log"
	"sync"

	"github.com/fatih/color"
)

// Runner listens change events and depending on that kills
// the obsolete process, and runs the new one
type Runner struct {
	running bool
	start   chan struct{}
	kill    chan struct{}

	mu *sync.Mutex
}

// NewRunner creates a new Runner instance and returns its pointer
func NewRunner() *Runner {
	return &Runner{
		running: false,
		start:   make(chan struct{}),
		kill:    make(chan struct{}),
		mu:      &sync.Mutex{},
	}
}

// Init initializes runner with given parameters.
func (r *Runner) Init(p *Params) {

	for {
		<-r.start

		color.Green("Running %s...\n", p.Get("run"))

		cmd, err := runCommand(getBinaryName(), p.Package...)
		if err != nil {
			log.Println("Could not run the go binary: %s", err)
			continue
		}

		go func() {
			r.mu.Lock()
			r.running = true
			r.mu.Unlock()
			cmd.Wait()
		}()

		go func() {
			<-r.kill
			pid := cmd.Process.Pid
			log.Printf("Killing PID %d \n", pid)
			cmd.Process.Kill()
		}()

	}
}

// Run runs the built package command
func (r *Runner) Run() {
	r.start <- struct{}{}
}

// Kill kills the obsolete process when the command is
// still running
func (r *Runner) Kill() {
	if r.running {
		r.kill <- struct{}{}
	}
}
