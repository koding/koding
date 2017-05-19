// Package vagrantutil is a high level wrapper around Vagrant which provides an
// idiomatic go API.
package vagrantutil

import (
	"bufio"
	"bytes"
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
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
)

// CommandOutput is the streaming output of a command
type CommandOutput struct {
	Line  string
	Error error
}

type Vagrant struct {
	// VagrantfilePath is the directory with specifies the directory where
	// Vagrantfile is being stored.
	VagrantfilePath string

	// ID is the unique ID of the given box
	ID string

	// State is populated/updated if the Status() or List() method is called.
	State string
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
	return ioutil.WriteFile(v.vagrantfile(), []byte(vagrantFile), 0644)
}

// Version returns the current installed vagrant version
func (v *Vagrant) Version() (string, error) {
	out, err := v.runVagrantCommand("version", "--machine-readable")
	if err != nil {
		return "", err
	}

	records, err := parseRecords(out)
	if err != nil {
		return "", err
	}

	versionInstalled, err := parseData(records, "version-installed")
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

	records, err := parseRecords(out)
	if err != nil {
		return Unknown, err
	}

	status, err := parseData(records, "state")
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

	records, err := parseRecords(out)
	if err != nil {
		return "", err
	}

	return parseData(records, "provider-name")
}

// List returns all available boxes on the system. Under the hood it calls
// "global-status" and parses the output.
func (v *Vagrant) List() ([]*Vagrant, error) {
	out, err := v.runVagrantCommand("global-status")
	if err != nil {
		return nil, err
	}

	output := make([][]string, 0)

	scanner := bufio.NewScanner(bytes.NewBufferString(out))
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
	return startCommand(cmd)
}

// Halt executes "vagrant halt". The returned reader contains the output
// stream. The client is responsible of calling the Close method of the
// returned reader.
func (v *Vagrant) Halt() (<-chan *CommandOutput, error) {
	cmd := v.vagrantCommand("halt")
	return startCommand(cmd)
}

// Destroy executes "vagrant destroy". The returned reader contains the output
// stream. The client is responsible of calling the Close method of the
// returned reader.
func (v *Vagrant) Destroy() (<-chan *CommandOutput, error) {
	cmd := v.vagrantCommand("destroy", "--force")
	return startCommand(cmd)
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
	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	return string(out), nil
}

// startCommand starts the command and sends back both the stdout and stderr to
// the returned channel. Any error happened during the streaming is passed to
// the Error field.
func startCommand(cmd *exec.Cmd) (<-chan *CommandOutput, error) {
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}

	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		return nil, err
	}

	if err := cmd.Start(); err != nil {
		return nil, err
	}

	var wg sync.WaitGroup
	out := make(chan *CommandOutput)

	output := func(r io.Reader) {
		wg.Add(1)
		scanner := bufio.NewScanner(r)
		for scanner.Scan() {
			out <- &CommandOutput{Line: scanner.Text(), Error: nil}
		}

		if err := scanner.Err(); err != nil {
			out <- &CommandOutput{Line: "", Error: err}
		}
		wg.Done()
	}

	go output(stdoutPipe)
	go output(stderrPipe)

	go func() {
		wg.Wait()
		if err := cmd.Wait(); err != nil {
			out <- &CommandOutput{Line: "", Error: err}
		}

		close(out)
	}()

	return out, nil
}

// parseData parses the given vagrant type field from the machine readable
// output (records).
func parseData(records [][]string, typeName string) (string, error) {
	data := ""
	for _, record := range records {
		// first three are defined, after that data is variadic, it contains
		// zero or more information. We should have a data, otherwise it's
		// useless.
		if len(record) < 4 {
			continue
		}

		if typeName == record[2] {
			data = record[3]
		}
	}

	if data == "" {
		return "", fmt.Errorf("couldn't parse data for vagrant type: '%s'", typeName)
	}

	return data, nil
}

func parseRecords(out string) ([][]string, error) {
	buf := bytes.NewBufferString(out)
	c := csv.NewReader(buf)
	return c.ReadAll()
}

// toStatus convers the given state string to Status type
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
	default:
		return Unknown, fmt.Errorf("Unknown state: %s", state)
	}

}
