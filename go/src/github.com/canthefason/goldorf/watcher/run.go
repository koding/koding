package watcher

import (
	"log"
	"os/exec"
	"sync"

	"github.com/fatih/color"
)

// Runner listens change events and depending on that kills
// the obsolete process, and runs the new one
type Runner struct {
	running  bool
	start    chan string
	kill     chan string
	done     chan struct{}
	fileName string

	mu *sync.Mutex
}

// NewRunner creates a new Runner instance and returns its pointer
func NewRunner() *Runner {
	return &Runner{
		running: false,
		start:   make(chan string),
		kill:    make(chan string),
		done:    make(chan struct{}),
		mu:      &sync.Mutex{},
	}
}

// Init initializes runner with given parameters.
func (r *Runner) Init(p *Params) {
	for {
		var fileName string
		select {
		case fileName = <-r.start:
		case <-r.done:
			return
		}

		color.Green("Running %s...\n", p.Get("run"))

		cmd, err := runCommand(fileName, p.Package...)
		if err != nil {
			log.Println("Could not run the go binary: %s", err)
			continue
		}

		go func(name string) {
			r.mu.Lock()
			r.running = true
			r.fileName = name
			r.mu.Unlock()
			cmd.Wait()
		}(fileName)

		go func() {
			select {
			case obsoleteFileName := <-r.kill:
				pid := cmd.Process.Pid
				log.Printf("Killing PID %d \n", pid)
				cmd.Process.Kill()
				if obsoleteFileName != "" {
					cmd := exec.Command("rm", obsoleteFileName)
					cmd.Run()
				}
			}
		}()

	}
}

// Run runs the built package command
func (r *Runner) Run(fileName string) {
	r.start <- fileName
}

// Kill kills the obsolete process when the command is
// still running
func (r *Runner) Kill(fileName string) {
	if r.running {
		r.kill <- fileName
	}
}

func (r *Runner) Close() {
	r.kill <- r.fileName
	close(r.kill)
	close(r.start)
}
