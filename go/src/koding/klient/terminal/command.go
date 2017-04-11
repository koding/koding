// +build !windows

package terminal

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"koding/kites/config"
	kos "koding/klient/os"

	"github.com/koding/passwd"
)

var (
	sessionPrefix      = "koding"
	defaultShell       = "/bin/bash"
	randomStringLength = 24 // 144 bit hex encoded
	screenEnv          []string
)

var defaultScreenPath = "/usr/bin/screen"

func init() {
	Reset()
}

// Reset is used to reconfigure terminal package when state of its dependencies
// changed in the runtime, e.g. embedded screen was installed.
func Reset() {
	const embeddedScreen = "/opt/kite/klient/embedded/bin/screen"

	term := ""

	if fi, err := os.Stat(embeddedScreen); err == nil && !fi.IsDir() {
		defaultScreenPath = embeddedScreen
		term = "screen-256color"
	}

	SetTerm(term)
}

// SetTerm changes the TERM environment variable used with
// screen processes.
//
// The function cannot be called after Terminal starts
// accepting kite requets.
func SetTerm(term string) {
	if term == "" {
		term = guessTerm()
	}

	screenEnv = (kos.Environ{
		"TERM": term,
		"HOME": config.CurrentUser.HomeDir,
	}).Encode(nil)
}

func guessTerm() string {
	terms := [][2]string{
		{"xterm-256color", "/usr/share/terminfo/x/xterm-256color"},
		{"xterm-256color", "/usr/share/terminfo/78/xterm-256color"},
		{"xterm-color", "/usr/share/terminfo/x/xterm-color"},
	}

	for _, term := range terms {
		if _, err := os.Stat(term[1]); err == nil {
			return term[0]
		}
	}

	return "xterm"
}

type Command struct {
	// Name is used for starting the terminal instance, it's the program path
	// usually
	Name string

	// Args is passed to the program name
	Args []string

	// Session id used for reconnections, used by screen or tmux
	Session string
}

var (
	ErrNoSession     = errors.New("session doesn't exists")
	ErrSessionExists = errors.New("session with the same name exists already")
)

func getUserEntry(username string) (*passwd.Entry, error) {
	entries, err := passwd.Parse()
	if err != nil {
		return nil, err
	}

	user, ok := entries[username]
	if !ok {
		return nil, err
	}

	if user.Shell == "" {
		return nil, err
	}

	return &user, nil
}

func getDefaultShell(username string) string {
	if runtime.GOOS == "darwin" {
		return defaultShell
	}

	entry, err := getUserEntry(username)
	if err != nil {
		log.Println("terminal: couldn't get default shell ", err)
		return defaultShell
	}

	return entry.Shell
}

// newCmd returns a new command instance that is used to start the terminal.
// The command line is created differently based on the incoming mode.
func (t *terminal) newCommand(mode, session, username string) (*Command, error) {
	// let's assume by default its Screen
	name := defaultScreenPath
	defaultShell := getDefaultShell(username)
	args := []string{"-e^Bb", "-s", defaultShell, "-S"}

	// TODO: resume and create are backwards compatible modes. Remove then once
	// the client side switched to use the "attach" mode which does both,
	// resume or create.
	switch mode {
	case "shared", "resume":
		if session == "" {
			return nil, errors.New("session is needed for 'shared' or 'resume' mode")
		}

		if !t.sessionExists(session, username) {
			return nil, ErrNoSession
		}

		args = append(args, sessionPrefix+"."+session)
		if mode == "shared" {
			args = append(args, "-x") // multiuser mode
		} else if mode == "resume" {
			args = append(args, "-raAd") // resume
		}
	case "noscreen":
		name = defaultShell
		args = []string{}
	case "attach", "create":
		if session == "" {
			// if the user didn't send a session name, create a custom
			// randomized
			session = randomString()
			args = append(args, sessionPrefix+"."+session)
		} else {
			// -a  : includes all capabilities
			// -A  : adapts the sizes of all windows to the current terminal
			// -DR : if session is running, re attach. If not create a new one
			args = append(args, sessionPrefix+"."+session, "-aADR")
		}
	default:
		return nil, fmt.Errorf("mode '%s' is unknown. Valid modes are:  [shared|noscreen|resume|create]", mode)
	}

	c := &Command{
		Name:    name,
		Args:    args,
		Session: session,
	}

	return c, nil
}

// screenSessions returns a list of sessions that belongs to the given
// username.  The sessions are in the form of ["k7sdjv12344", "askIj12sas12",
// ...]
// TODO: socket directory is different under darwin, it will not work probably
func (t *terminal) screenSessions(username string) []string {
	// Do not include dead sessions in our result
	t.run(defaultScreenPath, "-wipe")

	// We need to use ls here, because /tmp/uscreens mount is only
	// visible from inside of container. Errors are ignored.
	stdout, stderr, err := t.run("ls", "/tmp/uscreens/S-"+username)
	if err != nil {
		t.Log.Error("terminal: listing sessions failed: %s:\n%s\n", err, stderr)
		return nil
	}

	shellOut := string(bytes.TrimSpace(stdout))
	if shellOut == "" {
		return nil
	}

	names := strings.Split(shellOut, "\n")
	sessions := make([]string, len(names))

	prefix := sessionPrefix + "."
	for i, name := range names {
		segments := strings.SplitN(name, ".", 2)
		sessions[i] = strings.TrimPrefix(segments[1], prefix)
	}

	return sessions
}

// screenExists checks whether the given session exists in the running list of
// screen sessions.
func (t *terminal) sessionExists(session, username string) bool {
	for _, s := range t.screenSessions(username) {
		if s == session {
			return true
		}
	}

	return false
}

// killSessions kills all screen sessions for given username
func (t *terminal) killSessions(username string) error {
	for _, session := range t.screenSessions(username) {
		if err := t.killSession(session); err != nil {
			return err
		}
	}

	return nil
}

// killSession kills the given SessionID
func (t *terminal) killSession(session string) error {
	stdout, stderr, err := t.run(defaultScreenPath, "-X", "-S", sessionPrefix+"."+session, "kill")
	if err != nil {
		return commandError("screen kill failed", err, stdout, stderr)
	}

	return nil
}

func (t *terminal) renameSession(oldName, newName string) error {
	stdout, stderr, err := t.run(defaultScreenPath, "-X", "-S", sessionPrefix+"."+oldName, "sessionname", sessionPrefix+"."+newName)
	if err != nil {
		return commandError("screen renaming failed", err, stdout, stderr)
	}

	return nil
}

func commandError(message string, err error, stdout, stderr []byte) error {
	return fmt.Errorf("%s\n%s\n%s\n%s\n", message, err, stdout, stderr)
}

func (t *terminal) run(cmd string, args ...string) (stdout, stderr []byte, err error) {
	var bufout, buferr bytes.Buffer

	c := exec.Command(cmd, args...)
	c.Stdout = &bufout
	c.Stderr = &buferr
	c.Env = screenEnv

	t.Log.Debug("terminal: running: %v (%v)", c.Args, screenEnv)

	if err := c.Run(); err != nil {
		return nil, buferr.Bytes(), err
	}

	return bufout.Bytes(), nil, nil
}

func randomString() string {
	p := make([]byte, randomStringLength/2+1)
	rand.Read(p)
	return hex.EncodeToString(p)[:randomStringLength]
}
