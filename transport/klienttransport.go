package transport

import (
	"fmt"
	"io/ioutil"
	"os/user"
	"strings"
	"syscall"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

const (
	kiteName    = "fuseklient"
	kiteVersion = "0.0.1"
	kiteTimeout = 10 * time.Second
)

// KlientTransport is a Transport using Klient on user VM.
type KlientTransport struct {
	Client *kite.Client

	// The timeout Trip() uses for TellWithTimeout. If left empty, a zero timeout is
	// used, achieving the same result as Tell(), ie no timeout.
	TellTimeout time.Duration
}

// NewKlientTransport initializes KlientTransport with Klient connection.
func NewKlientTransport(klientIP string) (*KlientTransport, error) {
	k := kite.New(kiteName, kiteVersion)

	kiteClient := k.NewClient(fmt.Sprintf("http://%s:56789/kite", klientIP))

	// os/user has issues with cross compiling, so we may want to use
	// the following library instead:
	//
	// 	https://github.com/mitchellh/go-homedir
	usr, err := user.Current()
	if err != nil {
		return nil, err
	}

	data, err := ioutil.ReadFile(fmt.Sprintf(
		"%s/.fuseklient/keys/%s.kite.key", usr.HomeDir, klientIP,
	))
	if err != nil {
		return nil, err
	}

	kiteClient.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  strings.TrimSpace(string(data)),
	}
	kiteClient.Reconnect = true

	if err := kiteClient.DialTimeout(kiteTimeout); err != nil {
		return nil, err
	}

	return &KlientTransport{Client: kiteClient}, nil
}

// Trip is a generic method for communication. It accepts `req` to pass args
// to Klient and `res` to store unmarshalled response from Klient.
//
// If the method timeouts out, then we return syscall.ECONNREFUSED so it'll be
// shown to user by the kernel.
func (k *KlientTransport) Trip(methodName string, req interface{}, res interface{}) error {
	raw, err := k.Client.TellWithTimeout(methodName, k.TellTimeout, req)
	if err != nil {
		if kiteError, ok := err.(kite.Error); ok && kiteError.Type == "timeout" {
			return syscall.ECONNREFUSED
		}

		return err
	}

	return raw.Unmarshal(&res)
}
