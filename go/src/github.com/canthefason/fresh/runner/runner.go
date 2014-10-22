package runner

import (
	"os/exec"
	"strings"
)

func run() bool {
	var cmd *exec.Cmd
	if extArgs() != "" {
		args := strings.Split(extArgs(), " ")
		cmd = exec.Command(buildPath(), args...)
	} else {
		cmd = exec.Command(buildPath())
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		fatal(err)
	}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fatal(err)
	}

	err = cmd.Start()
	if err != nil {
		fatal(err)
	}

	go func() {
		cmd.Wait()
		select {
		case <-changeChannel:
		default:
			stopChannel <- true
			closeChannel <- true
		}

	}()

	go func() {
		<-stopChannel
		pid := cmd.Process.Pid
		runnerLog("Killing PID %d", pid)
		cmd.Process.Kill()
	}()

	return true
}
