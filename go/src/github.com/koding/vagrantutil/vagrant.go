// Package vagrantutil is a high level wrapper around Vagrant which provides an
// idiomatic go API.
package vagrantutil

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"

	"github.com/koding/logging"
)

//go:generate stringer -type=Status  -output=stringer.go

type Status int

const (
	// Some possible states:
	// https://github.com/mitchellh/vagrant/blob/master/templates/locales/en.yml#L1504
	Unknown Status = iota
	NotCreated
	Running
	Saved
	PowerOff
	Aborted
	Preparing
)

// Box represents a single line of `vagrant box list` output.
type Box struct {
	Name     string
	Provider string
	Version  string
}

// CommandOutput is the streaming output of a command
type CommandOutput struct {
	Line  string
	Error error
}

type Vagrant struct {
	// VagrantfilePath is the directory with specifies the directory where
	// Vagrantfile is being stored.
	VagrantfilePath string

	// ID is the unique ID of the given box.
	ID string

	// State is populated/updated if the Status() or List() method is called.
	State string

	// Log is used for logging output of vagrant commands in debug mode.
	Log logging.Logger
}

// NewVagrant returns a new Vagrant instance for the given path. The path
// should be unique. If the path already exists in the system it'll be used, if
// not a new setup will be createad.
func NewVagrant(path string) (*Vagrant, error) {
	if path == "" {
		return nil, errors.New("vagrant: path is empty")
	}

	if err := os.MkdirAll(path, 0755); err != nil {
		return nil, err
	}

	return &Vagrant{
		VagrantfilePath: path,
	}, nil
}

// Create creates the vagrantFile in the pre initialized vagrant path.
func (v *Vagrant) Create(vagrantFile string) error {
	// Recreate the directory in case it was removed between
	// call to NewVagrant and Create.
	if err := os.MkdirAll(v.VagrantfilePath, 0755); err != nil {
		return v.error(err)
	}

	v.debugf("create:\n%s", vagrantFile)

	return v.error(ioutil.WriteFile(v.vagrantfile(), []byte(vagrantFile), 0644))
}

// Version returns the current installed vagrant version
func (v *Vagrant) Version() (string, error) {
	out, err := v.runVagrantCommand("version", "--machine-readable")
	if err != nil {
		return "", err
	}

	records, err := v.parseRecords(out)
	if err != nil {
		return "", err
	}

	versionInstalled, err := v.parseData(records, "version-installed")
	if err != nil {
		return "", err
	}

	return versionInstalled, nil
}

// Status returns the state of the box, such as "Running", "NotCreated", etc...
func (v *Vagrant) Status() (s Status, err error) {
	defer func() {
		v.State = s.String()
	}()

	out, err := v.runVagrantCommand("status", "--machine-readable")
	if err != nil {
		return Unknown, err
	}

	records, err := v.parseRecords(out)
	if err != nil {
		return Unknown, err
	}

	status, err := v.parseData(records, "state")
	if err != nil {
		return Unknown, err
	}

	s, err = toStatus(status)
	if err != nil {
		return Unknown, err
	}

	return s, nil
}

func (v *Vagrant) Provider() (string, error) {
	out, err := v.runVagrantCommand("status", "--machine-readable")
	if err != nil {
		return "", err
	}

	records, err := v.parseRecords(out)
	if err != nil {
		return "", err
	}

	return v.parseData(records, "provider-name")
}

// List returns all available boxes on the system. Under the hood it calls
// "global-status" and parses the output.
func (v *Vagrant) List() ([]*Vagrant, error) {
	out, err := v.runVagrantCommand("global-status")
	if err != nil {
		return nil, err
	}

	output := make([][]string, 0)

	scanner := bufio.NewScanner(strings.NewReader(out))
	collectStarted := false

	for scanner.Scan() {
		if strings.HasPrefix(scanner.Text(), "--") {
			scanner.Scan() // advance to next line
			collectStarted = true
		}

		if !collectStarted {
			continue
		}

		trimmedLine := strings.TrimSpace(scanner.Text())
		if trimmedLine == "" {
			break // we are finished with collecting the boxes
		}

		output = append(output, strings.Fields(trimmedLine))
	}
	if err := scanner.Err(); err != nil {
		return nil, v.error(err)
	}

	boxes := make([]*Vagrant, len(output))

	for i, box := range output {
		// example box: [0c269f6 default virtualbox aborted /Users/fatih/path]
		boxes[i] = &Vagrant{
			ID:              box[0],
			VagrantfilePath: box[len(box)-1],
			State:           box[3],
		}
	}

	return boxes, nil
}

// Up executes "vagrant up" for the given vagrantfile. The returned channel
// contains the output stream. At the end of the output, the error is put into
// the Error field if there is any.
func (v *Vagrant) Up() (<-chan *CommandOutput, error) {
	cmd := v.vagrantCommand("up")
	return v.startCommand(cmd)
}

// Halt executes "vagrant halt". The returned reader contains the output
// stream. The client is responsible of calling the Close method of the
// returned reader.
func (v *Vagrant) Halt() (<-chan *CommandOutput, error) {
	cmd := v.vagrantCommand("halt")
	return v.startCommand(cmd)
}

// Destroy executes "vagrant destroy". The returned reader contains the output
// stream. The client is responsible of calling the Close method of the
// returned reader.
func (v *Vagrant) Destroy() (<-chan *CommandOutput, error) {
	cmd := v.vagrantCommand("destroy", "--force")
	return v.startCommand(cmd)
}

var stripFmt = strings.NewReplacer("(", "", ",", "", ")", "")

// BoxList executes "vagrant box list", parses the output and returns all
// available base boxes.
func (v *Vagrant) BoxList() ([]*Box, error) {
	out, err := v.runVagrantCommand("box", "list")
	if err != nil {
		return nil, err
	}

	var boxes []*Box
	scanner := bufio.NewScanner(strings.NewReader(out))

	for scanner.Scan() {
		line := strings.TrimSpace(stripFmt.Replace(scanner.Text()))
		if line == "" {
			continue
		}

		var box Box
		n, err := fmt.Sscanf(line, "%s %s %s", &box.Name, &box.Provider, &box.Version)
		if err != nil {
			return nil, v.errorf("%s for line: %s", err, line)
		}
		if n != 3 {
			return nil, v.errorf("unable to parse output line: %s", line)
		}

		boxes = append(boxes, &box)
	}
	if err := scanner.Err(); err != nil {
		return nil, v.error(err)
	}

	return boxes, nil
}

// BoxAdd executes "vagrant box add" for the given box. The returned channel
// contains the output stream. At the end of the output, the error is put into
// the Error field if there is any.
//
// TODO(rjeczalik): BoxAdd does not support currently adding boxes directly
// from files.
func (v *Vagrant) BoxAdd(box *Box) (<-chan *CommandOutput, error) {
	args := append([]string{"box", "add"}, toArgs(box)...)
	cmd := v.vagrantCommand(args...)
	return v.startCommand(cmd)
}

// BoxRemove executes "vagrant box remove" for the given box. The returned channel
// contains the output stream. At the end of the output, the error is put into
// the Error field if there is any.
func (v *Vagrant) BoxRemove(box *Box) (<-chan *CommandOutput, error) {
	args := append([]string{"box", "remove"}, toArgs(box)...)
	cmd := v.vagrantCommand(args...)
	return v.startCommand(cmd)
}

// vagrantfile returns the Vagrantfile path
func (v *Vagrant) vagrantfile() string {
	return filepath.Join(v.VagrantfilePath, "Vagrantfile")
}

// vagrantfileExists checks if a Vagrantfile exists in the given path. It
// returns a nil error if exists.
func (v *Vagrant) vagrantfileExists() error {
	if _, err := os.Stat(v.vagrantfile()); os.IsNotExist(err) {
		return err
	}
	return nil
}

// vagrantCommand creates a command which is setup to be run next to
// Vagrantfile
func (v *Vagrant) vagrantCommand(args ...string) *exec.Cmd {
	cmd := exec.Command("vagrant", args...)
	cmd.Dir = v.VagrantfilePath
	return cmd
}

// runVagrantCommand is a helper function which runs the given subcommands and
// arguments with vagrant and returns the output
func (v *Vagrant) runVagrantCommand(args ...string) (string, error) {
	cmd := v.vagrantCommand(args...)
	cmd.Dir = v.VagrantfilePath

	v.debugf("executing: %v", cmd.Args)

	out, err := cmd.CombinedOutput()
	if err != nil {
		if len(out) != 0 {
			err = fmt.Errorf("%s: %s", err, out)
		}
		return "", v.error(err)
	}

	v.debugf("%s", out)

	return string(out), nil
}

func (v *Vagrant) debugf(format string, args ...interface{}) {
	if v.Log != nil {
		v.Log.New(v.VagrantfilePath).Debug(format, args...)
	}
}

func (v *Vagrant) errorf(format string, args ...interface{}) error {
	err := fmt.Errorf(format, args...)
	v.debugf("%s", err)
	return err
}

func (v *Vagrant) error(err error) error {
	if err != nil {
		v.debugf("%s", err)
	}
	return err
}

// startCommand starts the command and sends back both the stdout and stderr to
// the returned channel. Any error happened during the streaming is passed to
// the Error field.
func (v *Vagrant) startCommand(cmd *exec.Cmd) (<-chan *CommandOutput, error) {
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}

	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		return nil, err
	}

	v.debugf("executing: %v", cmd.Args)

	if err := cmd.Start(); err != nil {
		return nil, err
	}

	var wg sync.WaitGroup
	out := make(chan *CommandOutput)

	output := func(r io.Reader) {
		wg.Add(1)
		scanner := bufio.NewScanner(r)
		for scanner.Scan() {
			v.debugf("%s", scanner.Text())
			out <- &CommandOutput{Line: scanner.Text(), Error: nil}
		}

		if err := scanner.Err(); err != nil {
			out <- &CommandOutput{Line: "", Error: v.error(err)}
		}
		wg.Done()
	}

	go output(stdoutPipe)
	go output(stderrPipe)

	go func() {
		wg.Wait()
		if err := cmd.Wait(); err != nil {
			out <- &CommandOutput{Line: "", Error: v.error(err)}
		}

		close(out)
	}()

	return out, nil
}

// toArgs converts the given box to argument list for `vagrant box add/remove`
// commands
func toArgs(box *Box) (args []string) {
	if box.Provider != "" {
		args = append(args, "--provider", box.Provider)
	}
	if box.Version != "" {
		args = append(args, "--box-version", box.Version)
	}
	return append(args, box.Name)
}

// toStatus converts the given state string to Status type
func toStatus(state string) (Status, error) {
	switch state {
	case "running":
		return Running, nil
	case "not_created":
		return NotCreated, nil
	case "saved":
		return Saved, nil
	case "poweroff":
		return PowerOff, nil
	case "aborted":
		return Aborted, nil
	case "preparing":
		return Preparing, nil
	default:
		return Unknown, fmt.Errorf("Unknown state: %s", state)
	}

}
