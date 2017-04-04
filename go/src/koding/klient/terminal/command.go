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
	defaultEnv         = kos.NewEnviron(os.Environ()).Encode(kos.Environ{
		"TERM":      "xterm-256color",
		"HOME":      config.CurrentUser.HomeDir,
		"SCREENDIR": "/var/run/screen",
	})
)

var defaultScreenPath = "/usr/bin/screen"

func init() {
	const embeddedScreen = "/opt/kite/klient/embedded/bin/screen"

	if fi, err := os.Stat(embeddedScreen); err == nil && !fi.IsDir() {
		defaultScreenPath = embeddedScreen
	}
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
func newCommand(mode, session, username string) (*Command, error) {
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

		if !sessionExists(session, username) {
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
func screenSessions(username string) []string {
	// Do not include dead sessions in our result
	run(defaultScreenPath, "-wipe")

	// We need to use ls here, because /var/run/screen mount is only
	// visible from inside of container. Errors are ignored.
	stdout, stderr, err := run("ls", "/var/run/screen/S-"+username)
	if err != nil {
		log.Printf("terminal: listing sessions failed: %s:\n%s\n", err, stderr)
	}

	shellOut := string(bytes.TrimSpace(stdout))
	if shellOut == "" {
		return []string{}
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
func sessionExists(session, username string) bool {
	for _, s := range screenSessions(username) {
		if s == session {
			return true
		}
	}

	return false
}

// killSessions kills all screen sessions for given username
func killSessions(username string) error {
	for _, session := range screenSessions(username) {
		if err := killSession(session); err != nil {
			return err
		}
	}

	return nil
}

// killSession kills the given SessionID
func killSession(session string) error {
	stdout, stderr, err := run(defaultScreenPath, "-X", "-S", sessionPrefix+"."+session, "kill")
	if err != nil {
		return commandError("screen kill failed", err, stdout, stderr)
	}

	return nil
}

func renameSession(oldName, newName string) error {
	stdout, stderr, err := run(defaultScreenPath, "-X", "-S", sessionPrefix+"."+oldName, "sessionname", sessionPrefix+"."+newName)
	if err != nil {
		return commandError("screen renaming failed", err, stdout, stderr)
	}

	return nil
}

func commandError(message string, err error, stdout, stderr []byte) error {
	return fmt.Errorf("%s\n%s\n%s\n%s\n", message, err, stdout, stderr)
}

func run(cmd string, args ...string) (stdout, stderr []byte, err error) {
	var bufout, buferr bytes.Buffer

	c := exec.Command(cmd, args...)
	c.Stdout = &bufout
	c.Stderr = &buferr
	c.Env = defaultEnv

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
