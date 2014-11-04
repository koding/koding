package watcher

import (
	"log"
	"os/exec"
	"syscall"
)

// Build listens watch events from Watcher and sends messages to Runner
// when new changes are built.
func Build(w *Watcher, r *Runner, p *Params) {
	for {
		w.Wait()

		run := p.Get("run")
		if run == "" {
			run = "."
		}

		log.Printf("Building %s...\n", run)

		cmd, err := runCommand("go", "build", "-o", getBinaryName(), run)
		if err != nil {
			log.Fatalf("Could not run 'go build' command: %s", err)
			continue
		}

		if err := cmd.Wait(); err != nil {
			if err := interpretError(err); err != nil {
				log.Fatal("An error occurred while building")
			}

			log.Println("A build error occurred. Please update your code...")

			continue
		}

		// when binary is successfully updated, kill the old running process
		r.Kill()

		// and start the new process
		r.Run()
	}
}

// interpretError checks the error, and returns nil if it is
// an exit code 2 error. Otherwise error is returned as it is.
// when a compilation error occurres, it returns with code 2.
func interpretError(err error) error {
	exiterr, ok := err.(*exec.ExitError)
	if !ok {
		return err
	}

	status, ok := exiterr.Sys().(syscall.WaitStatus)
	if !ok {
		return err
	}

	if status.ExitStatus() == 2 {
		return nil
	}

	return err
}
