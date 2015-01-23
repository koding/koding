package watcher

import (
	"fmt"
	"io"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"time"
)

// Binary name used for built package
const binaryName = "goldorf-main"

type Params struct {
	// Package parameters
	Package []string
	// Goldorf parameters
	System map[string]string
}

// NewParams creates a new instance of Params and returns the pointer
func NewParams() *Params {
	return &Params{
		Package: make([]string, 0),
		System:  make(map[string]string),
	}
}

// Get returns the goldorf parameter with given name
func (p *Params) Get(name string) string {
	return p.System[name]
}

// CloneRun copies run parameter value to watch parameter in-case watch
// parameter does not exist
func (p *Params) CloneRun() {
	if p.System["watch"] == "" && p.System["run"] != "" {
		p.System["watch"] = p.System["run"]
	}
}

// GetBinaryName prepares binary name with GOPATH if it is set
func getBinaryName() string {
	rand.Seed(time.Now().UnixNano())
	randName := rand.Int31n(999999)

	return fmt.Sprintf("%s-%d", getBinaryNameRoot(), randName)
}

func getBinaryNameRoot() string {
	path := os.Getenv("GOPATH")
	if path != "" {
		return fmt.Sprintf("%s/bin/%s", path, binaryName)
	}

	return path
}

func removeOldFiles() {
	exec.Command("rm", fmt.Sprintf("%s-*", getBinaryNameRoot()))
}

// runCommand runs the command with given name and arguments. It copies the
// logs to standard output
func runCommand(name string, args ...string) (*exec.Cmd, error) {
	cmd := exec.Command(name, args...)
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return cmd, err
	}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return cmd, err
	}

	if err := cmd.Start(); err != nil {
		return cmd, err
	}

	go io.Copy(os.Stdout, stdout)
	go io.Copy(os.Stderr, stderr)

	return cmd, nil
}

// PrepareArgs filters the system parameters from package parameters
// and returns Params instance
func PrepareArgs(args []string) *Params {

	params := NewParams()

	// remove command
	args = args[1:len(args)]

	for i := 0; i < len(args); i++ {
		arg := args[i]
		arg = stripDash(arg)

		if arg == "run" || arg == "watch" {
			if len(args) <= i+1 {
				log.Fatalf("missing parameter value: %s", arg)
			}

			params.System[arg] = args[i+1]
			i++
			continue
		}

		params.Package = append(params.Package, args[i])
	}

	params.CloneRun()

	return params
}

// stripDash removes the dash chars and returns parameter name
func stripDash(arg string) string {
	if len(arg) > 1 {
		if arg[1] == '-' {
			return arg[2:]
		} else if arg[0] == '-' {
			return arg[1:]
		}
	}

	return arg
}
