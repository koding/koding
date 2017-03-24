package registration

import (
	"bufio"
	"errors"
	"fmt"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"time"

	cfg "koding/kites/config"
	konfig "koding/klient/config"
	"koding/klient/tunnel/tlsproxy"
	configcli "koding/klientctl/endpoint/config"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
)

// Register registers with the username to the given kontrolURL via the users
// password or the given token.
func Register(koding *url.URL, username, token string, debug bool) error {
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
	newKonfig := cfg.NewKonfigURL(koding)

	if konfig := configcli.List()[newKonfig.ID()]; konfig != nil && konfig.KiteKey != "" {
		result, err := ask(fmt.Sprintf("An existing kite.key for %s detected. Type 'yes' to override and continue:", konfig.KodingPublic()))
		if err != nil {
			return err
		}

		if result != "yes" {
			return errors.New("aborting registration")
		}
	}

	kontrol := k.NewClient(newKonfig.Endpoints.Kontrol().Public.String())

	if err := kontrol.DialTimeout(30 * time.Second); err != nil {
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
	// is then transferred back to Kontrol. If we have a token, it will not ask
	// for a password and will create retunr the key immediately if the token
	// is valid for the given username (which is passed via the args).
	result, err := kontrol.TellWithTimeout("registerMachine", 5*time.Minute, args)
	if err != nil {
		return err
	}

	newKonfig.KiteKey = result.MustString()

	if err := configcli.Use(newKonfig); err != nil {
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
