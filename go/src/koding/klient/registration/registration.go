package registration

import (
	"bufio"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"time"

	konfig "koding/klient/config"
	"koding/klient/tunnel/tlsproxy"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
)

// Register registers with the username to the given kontrolURL via the users
// password or the given token.
func Register(kontrolURL, kiteHome, username, token string, debug bool) error {
	var err error

	// Open up a prompt if the username is not passed via a flag and it's not a
	// token based authentication. If token is empty, it means the user can be
	// authenticated via password
	if token == "" && username == "" {
		username, err = ask("Username:")
		if err != nil {
			return err
		}
		// User can just press enter to use the default on the prompt
		if username == "" {
			return errors.New("Username can not be empty.")
		}
	}

	k := kite.New("klient", konfig.Version)
	k.Config.Environment = konfig.Environment
	k.Config.Region = konfig.Region
	k.Config.Username = username

	if debug {
		k.SetLogLevel(kite.DEBUG)
	}

	// Production Koding servers are only working over HTTP
	k.Config.Transport = config.XHRPolling

	// Give a warning if an existing kite.key exists
	kiteKeyPath := kiteHome + "/kite.key"
	if _, err := readKey(kiteKeyPath); err == nil {
		result, err := ask(fmt.Sprintf("An existing %s detected. Type 'yes' to override and continue:", kiteKeyPath))
		if err != nil {
			return err
		}

		if result != "yes" {
			return errors.New("aborting registration")
		}
	}

	kontrol := k.NewClient(kontrolURL)
	if err := kontrol.Dial(); err != nil {
		return err
	}
	defer kontrol.Close()

	// Register is always called with sudo, so Init should have enough
	// permissions.
	if err := tlsproxy.Init(); err != nil {
		return err
	}

	authType := "password"
	if token != "" {
		authType = "token"
	}

	var args = struct {
		Username string
		Token    string
		AuthType string
	}{
		Username: username,
		Token:    token,
		AuthType: authType,
	}

	// If authtType is password, this causes Kontrol to execute the
	// 'kite.getPass' method (builtin method in the Kite library) on our own
	// local kite (the one we declared above) method bidirectional. So once we
	// execute this, we immediately get a prompt asking for our password, which
	// is then transfered back to Kontrol. If we have a token, it will not ask
	// for a password and will create retunr the key immediately if the token
	// is valid for the given username (which is passed via the args).
	result, err := kontrol.TellWithTimeout("registerMachine", 5*time.Minute, args)
	if err != nil {
		return err
	}

	// If the token is correct a valid and signed `kite.key` is returned
	// back. We go and create/override the ~/.kite/kite.key with this content.
	if err := writeKey(result.MustString(), kiteKeyPath); err != nil {
		return err
	}

	// Using authenticated here instead of registered, so it is a
	// middleground in UX for both raw `klient -register` usage, and also
	// `kd install` usage. `kd install` is very user facing, and
	// registration is potentially confusing to the end user (since
	// they are already registered to koding.com.. etc)
	fmt.Println("Authenticated successfully")
	return nil
}

func writeKey(kiteKey, filename string) error {
	err := os.MkdirAll(filepath.Dir(filename), 0700)
	if err != nil {
		return err
	}

	// Need to remove the previous key first because we can't write over
	// when previos file's mode is 0400.
	os.Remove(filename)

	return ioutil.WriteFile(filename, []byte(kiteKey), 0400)
}

func readKey(filename string) (string, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(data)), nil
}

// ask asks for an input from standard input and returns the result back. It is
// extracted from mitcellh/cli to be used as a standalone function.
func ask(query string) (string, error) {
	if _, err := fmt.Fprint(os.Stdout, query+" "); err != nil {
		return "", err
	}

	// Register for interrupts so that we can catch it and immediately
	// return...
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt)
	defer signal.Stop(sigCh)

	// Ask for input in a go-routine so that we can ignore it.
	errCh := make(chan error, 1)
	lineCh := make(chan string, 1)
	go func() {
		r := bufio.NewReader(os.Stdin)
		line, err := r.ReadString('\n')
		if err != nil {
			errCh <- err
			return
		}

		lineCh <- strings.TrimRight(line, "\r\n")
	}()

	select {
	case err := <-errCh:
		return "", err
	case line := <-lineCh:
		return line, nil
	case <-sigCh:
		// Print a newline so that any further output starts properly
		// on a new line.
		fmt.Fprintln(os.Stdout)

		return "", errors.New("interrupted")
	}
}
