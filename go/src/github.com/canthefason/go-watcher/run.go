// Watcher is a command line tool inspired by fresh (https://github.com/pilu/fresh) and used
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

// Runner listens change events and depending on that kills
// the obsolete process, and runs the new one
type Runner struct {
	running  bool
	start    chan string
	done     chan struct{}
	fileName string
	cmd      *exec.Cmd

	mu *sync.Mutex
}

// NewRunner creates a new Runner instance and returns its pointer
func NewRunner() *Runner {
	return &Runner{
		running: false,
		start:   make(chan string),
		done:    make(chan struct{}),
		mu:      &sync.Mutex{},
	}
}

// Init initializes runner with given parameters.
func (r *Runner) Run(p *Params) {
	for fileName := range r.start {

		color.Green("Running %s...\n", p.Get("run"))

		cmd, err := runCommand(fileName, p.Package...)
		if err != nil {
			log.Printf("Could not run the go binary: %s", err)
			continue
		}
		r.cmd = cmd

		go func(name string) {
			r.mu.Lock()
			r.running = true
			r.fileName = name
			r.mu.Unlock()
			r.cmd.Wait()
		}(fileName)
	}
}

// Restart kills the process, removes the old binary and
// restarts the new process
func (r *Runner) restart(fileName string) {
	if r.running {
		r.kill()
		r.removeFile()
	}

	r.start <- fileName
}

func (r *Runner) kill() {
	pid := r.cmd.Process.Pid
	log.Printf("Killing PID %d \n", pid)
	r.cmd.Process.Kill()
}

func (r *Runner) removeFile() {
	if r.fileName != "" {
		cmd := exec.Command("rm", r.fileName)
		cmd.Run()
		cmd.Wait()
	}
}

func (r *Runner) Close() {
	r.kill()
	r.removeFile()
	close(r.start)
	close(r.done)
}

func (r *Runner) Wait() {
	<-r.done
}
