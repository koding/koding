package watcher

import (
	"fmt"
	"io"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"strings"
	"time"
)

// Binary name used for built package
const binaryName = "watcher"

var watcherFlags = []string{"run", "watch", "watch-vendor"}

// Params is used for keeping go-watcher and application flag parameters
type Params struct {
	// Package parameters
	Package []string
	// Go-Watcher parameters
	Watcher map[string]string
}

// NewParams creates a new Params instance
func NewParams() *Params {
	return &Params{
		Package: make([]string, 0),
		Watcher: make(map[string]string),
	}
}

// Get returns the watcher parameter with the given name
func (p *Params) Get(name string) string {
	return p.Watcher[name]
}

func (p *Params) cloneRunFlag() {
	if p.Watcher["watch"] == "" && p.Watcher["run"] != "" {
		p.Watcher["watch"] = p.Watcher["run"]
	}
}

func (p *Params) packagePath() string {
	run := p.Get("run")
	if run != "" {
		return run
	}

	return "."
}

// generateBinaryName generates a new binary name for each rebuild, for preventing any sorts of conflicts
func (p *Params) generateBinaryName() string {
	rand.Seed(time.Now().UnixNano())
	randName := rand.Int31n(999999)
	packageName := strings.Replace(p.packagePath(), "/", "-", -1)

	return fmt.Sprintf("%s-%s-%d", generateBinaryPrefix(), packageName, randName)
}

func generateBinaryPrefix() string {
	path := os.Getenv("GOPATH")
	if path != "" {
		return fmt.Sprintf("%s/bin/%s", path, binaryName)
	}

	return path
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

// ParseArgs extracts the application parameters from args and returns
// Params instance with separated watcher and application parameters
func ParseArgs(args []string) *Params {

	params := NewParams()

	// remove the command argument
	args = args[1:len(args)]

	for i := 0; i < len(args); i++ {
		arg := args[i]
		arg = stripDash(arg)

		if existIn(arg, watcherFlags) {
			// used for fetching the value of the given parameter
			if len(args) <= i+1 {
				log.Fatalf("missing parameter value: %s", arg)
			}

			if strings.HasPrefix(args[i+1], "-") {
				log.Fatalf("missing parameter value: %s", arg)
			}

			params.Watcher[arg] = args[i+1]
			i++
			continue
		}

		params.Package = append(params.Package, args[i])
	}

	params.cloneRunFlag()

	return params
}

// stripDash removes the both single and double dash chars and returns
// the actual parameter name
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

func existIn(search string, in []string) bool {
	for i := range in {
		if search == in[i] {
			return true
		}
	}

	return false
}

func removeFile(fileName string) {
	if fileName != "" {
		cmd := exec.Command("rm", fileName)
		cmd.Run()
		cmd.Wait()
	}
}
