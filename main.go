package main

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kitekey"
	"github.com/koding/klient/app"
	"github.com/koding/klient/protocol"
)

var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 56789, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagEnvironment = flag.String("env", protocol.Environment, "Change environment")
	flagRegion      = flag.String("region", protocol.Region, "Change region")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
	flagDebug       = flag.Bool("debug", false, "Debug mode")
	flagScreenrc    = flag.String("screenrc", "/opt/koding/etc/screenrc", "Default screenrc path")

	// Registration flags
	flagUsername   = flag.String("username", "", "Username to be registered to Kontrol")
	flagRegister   = flag.Bool("register", false, "Register to Kontrol with your Koding Password")
	flagKontrolURL = flag.String("kontrol-url", "https://koding.com/kontrol/kite",
		"Change kontrol URL to be used for registration")

	// update parameters
	flagUpdateInterval = flag.Duration("update-interval", time.Minute*5,
		"Change interval for checking for new updates")
	flagUpdateURL = flag.String("update-url",
		"https://s3.amazonaws.com/koding-klient/"+protocol.Environment+"/latest-version.txt",
		"Change update endpoint for latest version")
)

func main() {
	// Call realMain instead of doing the work here so we can use
	// `defer` statements within the function and have them work properly.
	// (defers aren't called with os.Exit)
	os.Exit(realMain())
}

func realMain() int {
	flag.Parse()
	if *flagVersion {
		fmt.Println(protocol.Version)
		return 0
	}

	if *flagRegister {
		if err := registerWithPassword(*flagKontrolURL, *flagUsername); err != nil {
			fmt.Fprint(os.Stderr, err.Error())
			return 1
		}
		return 0
	}

	conf := &app.KlientConfig{
		Name:           protocol.Name,
		Version:        protocol.Version,
		IP:             *flagIP,
		Port:           *flagPort,
		Environment:    *flagEnvironment,
		Region:         *flagRegion,
		RegisterURL:    *flagRegisterURL,
		Debug:          *flagDebug,
		UpdateInterval: *flagUpdateInterval,
		UpdateURL:      *flagUpdateURL,
		ScreenrcPath:   *flagScreenrc,
	}

	a := app.NewKlient(conf)
	defer a.Close()

	// Run Forrest, Run!
	a.Run()

	return 0
}

// registerWithPassword registers to the given kontrolURL. The user
func registerWithPassword(kontrolURL, username string) error {
	var err error

	// Open up a prompt if the username is not passed via a flag
	if username == "" {
		username, err = ask("Username:")
		if err != nil {
			return err
		}
		// User can just press enter to use the default on the prompt
		if username == "" {
			return errors.New("Username can not be empty.")
		}
	}

	k := kite.New("klient", protocol.Version)
	k.Config.Environment = protocol.Environment
	k.Config.Region = protocol.Region
	k.Config.Transport = config.XHRPolling
	k.Config.Username = username

	if _, err := kitekey.Read(); err == nil {
		fmt.Println("Already registered. Registering again...")
	}

	kontrol := k.NewClient(kontrolURL)
	if err := kontrol.Dial(); err != nil {
		return err
	}

	result, err := kontrol.TellWithTimeout("registerMachine", 5*time.Minute, username)
	if err != nil {
		return err
	}

	if err := kitekey.Write(result.MustString()); err != nil {
		return err
	}

	fmt.Println("Registered successfully")
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
