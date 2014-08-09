package terminal

import (
	"bytes"
	"errors"
	"fmt"
	"os/exec"
	"strings"
)

const (
	sessionPrefix     = "koding"
	defaultScreenPath = "/usr/bin/screen"
)

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
	ErrNoSession      = errors.New("ErrNoSession")
	ErrInvalidSession = errors.New("ErrInvalidSession")
)

// newCmd returns a new command instance that is used to start the terminal.
// The command line is created differently based on the incoming mode.
func newCommand(mode, session, username string) (*Command, error) {
	// let's assume by default its Screen
	name := defaultScreenPath
	args := []string{"-e^Bb", "-s", "/bin/bash", "-S"}

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
		name = "/bin/bash"
		args = []string{}
	case "create":
		session = randomString()
		args = append(args, sessionPrefix+"."+session)
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
	exec.Command(defaultScreenPath, "-wipe").Run()

	// We need to use ls here, because /var/run/screen mount is only
	// visible from inside of container. Errors are ignored.
	out, _ := exec.Command("ls", "/var/run/screen/S-"+username).Output()
	shellOut := string(bytes.TrimSpace(out))
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

// killSession kills the given SessionID
func killSession(session string) error {
	out, err := exec.Command(defaultScreenPath, "-X", "-S", sessionPrefix+"."+session, "kill").Output()
	if err != nil {
		return commandError("screen kill failed", err, out)
	}

	return nil
}

func commandError(message string, err error, out []byte) error {
	return fmt.Errorf("%s\n%s\n%s", message, err.Error(), string(out))
}
