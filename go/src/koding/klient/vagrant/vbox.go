package vagrant

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
)

// testExec is a custom fn that executes a command specified by cmd and args
// parameters and returns the command's output.
var testExec func(cmd string, args ...string) ([]byte, error)

func execCmd(cmd string, args ...string) ([]byte, error) {
	if testExec != nil {
		return testExec(cmd, args...)
	}

	return exec.Command(cmd, args...).Output()
}

type OutputFuncs []func(string)

func (fns OutputFuncs) Output(line string) {
	for _, fn := range fns {
		fn(line)
	}
}

var vboxModules = []string{
	"vboxguest",
	"vboxsf",
	"vboxvideo",
}

func IsVagrant() (bool, error) {
	if runtime.GOOS != "linux" {
		return false, nil // TODO(rjeczalik): Windows support
	}

	return isVagrant()
}

func isVagrant() (bool, error) {
	p, err := execCmd("lsmod")
	if err != nil {
		return false, errors.New("IsVagrant error: " + err.Error())
	}

	for {
		// a single line of lsmod output is in format:
		//
		//  module             249035  2 modules
		//
		// if at least one VirtualBox module is loaded into kernel,
		// it means it's a vagrant box.
		i := bytes.IndexByte(p, ' ')
		if i == -1 {
			break
		}

		module := string(p[:i])

		for _, vboxModule := range vboxModules {
			if module == vboxModule {
				return true, nil
			}
		}

		if i = bytes.IndexByte(p, '\n'); i == -1 {
			break
		}

		p = p[i+1:]
	}

	return false, nil
}

func (h *Handlers) vboxLookupName(partial string) (fullName string, err error) {
	p, err := execCmd("VBoxManage", "list", "vms")
	if err != nil {
		return "", err
	}

	scanner := bufio.NewScanner(bytes.NewReader(p))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if i := strings.IndexRune(line, ' '); i != -1 {
			line = line[:i]
		}
		if s, err := strconv.Unquote(line); err == nil {
			line = s
		}

		if strings.HasPrefix(line, partial) {
			if fullName != "" {
				return "", fmt.Errorf("multiple boxes found for %q: %q, %q", partial, fullName, line)
			}

			fullName = line
		}
	}
	if err := scanner.Err(); err != nil {
		return "", err
	}

	if fullName == "" {
		return "", fmt.Errorf("no box found for %q", partial)
	}

	return fullName, nil
}

func (h *Handlers) vboxForwardedPorts(name string) (ports []*ForwardedPort, err error) {
	p, err := execCmd("VBoxManage", "showvminfo", name, "--machinereadable")
	if err != nil {
		return nil, err
	}

	scanner := bufio.NewScanner(bytes.NewReader(p))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if !strings.HasPrefix(line, "Forwarding") {
			continue
		}

		if i := strings.IndexRune(line, '='); i != -1 {
			line = line[i+1:]
		}

		if s, err := strconv.Unquote(line); err == nil {
			line = s
		}

		// forwarding rule is in format "tcp56788,tcp,,56788,,56789", where
		// 56788 is host port and 56789 a guest one.
		v := strings.Split(line, ",")

		if len(v) != 6 || v[3] == "" || v[5] == "" {
			h.log().Debug("forwarding rule is ill-formatted: %s", line)
			continue
		}

		hostPort, err := strconv.Atoi(v[3])
		if err != nil {
			h.log().Debug("forwarding rule: parsing host port error: %s", err)
			continue
		}

		guestPort, err := strconv.Atoi(v[5])
		if err != nil {
			h.log().Debug("forwarding rule: parsing guest port error: %s", err)
			continue
		}

		ports = append(ports, &ForwardedPort{GuestPort: guestPort, HostPort: hostPort})
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return ports, nil
}
