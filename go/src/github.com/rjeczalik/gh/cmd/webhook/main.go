// Command webhook starts a web server which listens on GitHub's POST requests.
// The payload of each request is verified against its signature, unmarshalled
// into corresponding event struct and the applied to the template script provided
// by a user.
//
// Usage
//
//   webhook [-cert file -key file] [-addr address] [-log file] -secret key script
//
// The struct being passed to the template script is:
//
//   type Event struct {
//   	Name    string
//   	Payload interface{}
//   	Args    map[string]string
//   }
//
// The Name field denotes underlying type for the Payload. Full mapping between
// possible Name values and Payload types is listed in the documentation of
// the webhook package. The Args field contains all command line flags passed
// to template script.
//
// Template scripts use template syntax of text/template package. Each template
// script has registered extra control functions:
//
//   env
//   	An alias for os.Getenv.
//   log
//   	An alias for log.Println. Used only for side-effect, returns empty string.
//   logf
//   	An alias for log.Printf. Used only for side-effect, returns empty string.
//   exec
//   	An alias for exec.Command. Returned value is the process' output read
//   	from its os.Stdout.
//
// Example
//
// In order to log an e-mail of each person that pushed to your repository, create
// a template script with the following content:
//
//   $ cat >push.tsc <<EOF
//   > {{if .Name | eq "push"}}
//   >   {{logf "%s pushed to %s" .Payload.Pusher.Email .Payload.Repository.Name}}
//   > {{endif}}
//   > EOF
//
// And start the webhook:
//
//   $ webhook -secret secret123 push.tsc
//   2015/03/13 21:32:15 INFO Listening on [::]:8080 . . .
//
// Webhook listens on 0.0.0.0:8080 by default.
//
// Template scripts input
//
// Template scripts support currently two of ways accepting input:
//
//   - via {{env "VARIABLE"}} function
//   - and via command lines arguments
//
// Positional arguments that follow double-dash argument are turned into map[string]string
// value, which is then passed as Args field of an Event.
//
// Example
//
// The command line arguments passed after -- for the following command line
//
//   $ webhook -secret secret123 examples/slack.tsc -- -token token123 -channel CH123
//
// are passed to the script as
//
//   ...
//   Args: map[string]string{
//   	"Token":   "token123",
//   	"Channel": "CH123",
//   },
//   ...
//
// The -cert and -key flags are used to provide paths for the certificate and private
// key files. When specified, webhook serves HTTPS connections by default on 0.0.0.0:8443.
//
// The -addr flag can be used to specify a network address for the webhook to listen on.
//
// The -secret flag sets the secret value to verify the signature of GitHub's payloads.
// The value is required and cannot be empty.
//
// The -log flag redirects output to the given file.
//
// The -dump flag makes webhook dump each received JSON payload into specified
// directory. The file is named after <event>-<delivery>.json, where:
//
//   - <event> is a value of X-GitHub-Event header
//   - <delivery> is a value of X-GitHub-Delivery header
//
// The script argument is a path to the template script file which is used as a handler
// for incoming events.
package main

import (
	"crypto/rand"
	"crypto/tls"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"

	"github.com/rjeczalik/gh/cmd/internal/tsc"
	"github.com/rjeczalik/gh/webhook"
)

const usage = `usage: webhook [-cert file -key file] [-addr address] [-log file] -secret key script

Starts a web server which listens on GitHub's POST requests. The payload of each
request is verified against its signature, unmarshalled into corresponding event
struct and the applied to the template script provided by a user.

The struct being passed to the template script is:

	type Event struct {
		Name    string
		Payload interface{}
		Args    map[string]string
	}

The Name field denotes underlying type for the Payload. Full mapping between
possible Name values and Payload types is listed in the documentation of
the webhook package. The Args field contains all command line flags passed
to template script.

Template scripts use template syntax of text/template package. Each template
script has registered extra control functions:

	env
		An alias for os.Getenv.
	log
		An alias for log.Println. Used only for side-effect, returns empty string.
	logf
		An alias for log.Printf. Used only for side-effect, returns empty string.
	exec
		An alias for exec.Command. Returned value is the process' output read
		from its os.Stdout.

Example

In order to log an e-mail of each person that pushed to your repository, create
a template script with the following content:

	$ cat >push.tsc <EOF
	> {{if .Name eq "push"}}
	>   {{logf "%s pushed to %s" .Payload.Pusher.Email .Payload.Repository.Name}}
	> {{endif}}
	> EOF

And start the webhook:

	$ webhook -secret secret123 push.tsc
	2015/03/13 21:32:15 INFO Listening on [::]:8080 . . .

Webhook listens on 0.0.0.0:8080 by default.

Template scripts input

Template scripts support currently two of ways accepting input:

	- via {{env "VARIABLE"}} function
	- and via command lines arguments

Positional arguments that follow double-dash argument are turned into map[string]string
value, which is then passed as Args field of an Event.

Example

The command line arguments passed after -- for the following command line

	$ webhook -secret secret123 examples/slack.tsc -- -token token123 -channel CH123

are passed to the script as

	...
	Args: map[string]string{
		"Token":   "token123",
		"Channel": "CH123",
	},
	...

The -cert and -key flags are used to provide paths for certificate and private
key files. When specified, webhook serves HTTPS connection by default on 0.0.0.0:8443.

The -addr flag can be used to specify a network address for the webhook to listen on.

The -secret flag sets the secret value to verify the signature of GitHub's payloads.
The value is required and cannot be empty.

The -log flag redirects output to the given file.

The -dump flag makes webhook dump each received JSON payload into specified
directory. The file is named after <event>-<delivery>.json, where:

	- <event> is a value of X-GitHub-Event header
	- <delivery> is a value of X-GitHub-Delivery header

The script argument is a path to the template script file which is used as a handler
for incoming events.`

var (
	cert    = flag.String("cert", "", "Certificate file.")
	key     = flag.String("key", "", "Private key file.")
	addr    = flag.String("addr", "", "Network address to listen on. Default is :8080 for HTTP and :8443 for HTTPS.")
	secret  = flag.String("secret", "", "GitHub secret value used for signing payloads.")
	debug   = flag.Bool("debug", false, "Dumps verified payloads into testdata directory.")
	dump    = flag.String("dump", "", "Dumps verified payloads into given directory.")
	logfile = flag.String("log", "", "Redirects output to the given file.")
)

func nonil(s ...string) string {
	for _, s := range s {
		if s != "" {
			return s
		}
	}
	return ""
}

func die(v interface{}) {
	fmt.Fprintln(os.Stderr, v)
	os.Exit(1)
}

func main() {
	if len(os.Args) == 1 {
		die(usage)
	}
	flag.CommandLine.Usage = func() {
		fmt.Fprintln(os.Stderr, usage)
	}
	flag.Parse()
	if flag.NArg() == 0 || flag.Arg(0) == "" {
		die("missing script file")
	}
	if (*cert == "") != (*key == "") {
		die("both -cert and -key flags must be provided")
	}
	if *debug && *dump == "" {
		*dump = "testdata"
	}
	if *logfile != "" {
		f, err := os.OpenFile(*logfile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			die(err)
		}
		log.SetOutput(f)
		defer f.Close()
	}
	var arg string
	var args = os.Args
	for len(args) != 0 {
		arg, args = args[0], args[1:]
		if arg == "--" {
			break
		}
	}
	sc, err := tsc.New(flag.Arg(0), args)
	if err != nil {
		die(err)
	}
	var listener net.Listener
	if *cert != "" {
		crt, err := tls.LoadX509KeyPair(*cert, *key)
		if err != nil {
			die(err)
		}
		cfg := &tls.Config{
			Certificates: []tls.Certificate{crt},
			Rand:         rand.Reader,
			// Don't offer SSL3.
			MinVersion: tls.VersionTLS10,
			// Workaround TLS_FALLBACK_SCSV bug. For details see:
			// https://go-review.googlesource.com/#/c/1776/
			MaxVersion: tls.VersionTLS12,
			// Don't offer RC4 ciphers.
			CipherSuites: []uint16{
				tls.TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,
				tls.TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,
				tls.TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA,
				tls.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,
				tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
				tls.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,
				tls.TLS_RSA_WITH_3DES_EDE_CBC_SHA,
				tls.TLS_RSA_WITH_AES_128_CBC_SHA,
				tls.TLS_RSA_WITH_AES_256_CBC_SHA,
			},
		}
		l, err := tls.Listen("tcp", nonil(*addr, "0.0.0.0:8443"), cfg)
		if err != nil {
			die(err)
		}
		listener = l
	} else {
		l, err := net.Listen("tcp", nonil(*addr, "0.0.0.0:8080"))
		if err != nil {
			die(err)
		}
		listener = l
	}
	var handler http.Handler = webhook.New(*secret, sc)
	if *dump != "" {
		handler = webhook.Dump(*dump, handler)
	}
	log.Printf("INFO Listening on %s . . .", listener.Addr())
	if err := http.Serve(listener, handler); err != nil {
		die(err)
	}
}
