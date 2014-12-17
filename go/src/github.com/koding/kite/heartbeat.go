package kite

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/koding/kite/dnode"
	"github.com/koding/kite/protocol"
)

type kontrolFunc func(*Client) error

// kontrolFunc setups and prepares a kontrol instance. It connects to
// kontrol and providers a way to call the given function in that connected
// kontrol environment. This method is called internally whenever a kontrol
// client specific action is taking (getKites, getToken, register). The main
// reason for having this is doing the call and close the connection
// immediately, so there will be no persistent connection.
func (k *Kite) kontrolFunc(fn kontrolFunc) error {
	if k.Config.KontrolURL == "" {
		return errors.New("no kontrol URL given in config")
	}

	client := k.NewClient(k.Config.KontrolURL)

	client.Kite = protocol.Kite{Name: "kontrol"} // for logging purposes
	client.Auth = &Auth{
		Type: "kiteKey",
		Key:  k.Config.KiteKey,
	}

	if err := client.Dial(); err != nil {
		return err
	}
	defer client.Close()

	return fn(client)
}

// RegisterHTTPForever is just like RegisterHTTP however it first tries to
// register forever until a response from kontrol is received. It's useful to
// use it during app initializations. After the registration a reconnect is
// automatically handled inside the RegisterHTTP method.
func (k *Kite) RegisterHTTPForever(kiteURL *url.URL) {
	interval := time.NewTicker(kontrolRetryDuration)
	defer interval.Stop()

	_, err := k.RegisterHTTP(kiteURL)
	if err == nil {
		return
	}

	for _ = range interval.C {
		_, err := k.RegisterHTTP(kiteURL)
		if err == nil {
			return
		}

		k.Log.Error("Cannot register to Kontrol: %s Will retry after %d seconds",
			err, kontrolRetryDuration/time.Second)

	}
}

// RegisterHTTP registers current Kite to Kontrol. After registration other Kites
// can find it via GetKites() or WatchKites() method. It registers again if
// connection to kontrol is lost.
func (k *Kite) RegisterHTTP(kiteURL *url.URL) (*registerResult, error) {
	var response *dnode.Partial

	registerFunc := func(kontrol *Client) error {
		args := protocol.RegisterArgs{
			URL: kiteURL.String(),
		}

		k.Log.Info("Registering to kontrol with URL (via HTTP): %s", kiteURL.String())
		var err error
		response, err = kontrol.TellWithTimeout("registerHTTP", 4*time.Second, args)
		return err
	}

	if err := k.kontrolFunc(registerFunc); err != nil {
		return nil, err
	}

	var rr protocol.RegisterResult
	if err := response.Unmarshal(&rr); err != nil {
		return nil, err
	}

	parsed, err := url.Parse(rr.URL)
	if err != nil {
		k.Log.Error("Cannot parse registered URL: %s", err.Error())
	}

	heartbeat := time.Duration(rr.HeartbeatInterval) * time.Second

	k.Log.Info("Registered (via HTTP) with URL: '%s' and HeartBeat interval: '%s'",
		rr.URL, heartbeat)

	go k.sendHeartbeats(heartbeat, kiteURL)

	return &registerResult{parsed}, nil
}

func (k *Kite) sendHeartbeats(interval time.Duration, kiteURL *url.URL) {
	tick := time.NewTicker(interval)

	var heartbeatURL string
	if strings.HasSuffix(k.Config.KontrolURL, "/kite") {
		heartbeatURL = strings.TrimSuffix(k.Config.KontrolURL, "/kite") + "/heartbeat"
	} else {
		heartbeatURL = k.Config.KontrolURL + "/heartbeat"
	}

	k.Log.Debug("Sending heartbeat to: %s", heartbeatURL)

	u, err := url.Parse(heartbeatURL)
	if err != nil {
		k.Log.Fatal("HeartbeatURL is malformed: %s", err)
	}

	q := u.Query()
	q.Set("id", k.Id)
	u.RawQuery = q.Encode()

	errRegisterAgain := errors.New("register again")

	client := &http.Client{
		Timeout: time.Second * 10,
	}

	heartbeatFunc := func() error {
		k.Log.Debug("Sending heartbeat to %s", u.String())

		resp, err := client.Get(u.String())
		if err != nil {
			return err
		}
		defer resp.Body.Close()

		// we are just receving small size strings such as "pong",
		// "registeragain" so it's totally normal to consume the whole response
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return err
		}

		k.Log.Debug("Heartbeat response received '%s'", strings.TrimSpace(string(body)))

		switch string(body) {
		case "pong":
			return nil
		case "registeragain":
			tick.Stop()
			k.RegisterHTTP(kiteURL)
			return errRegisterAgain
		}

		return fmt.Errorf("malformed heartbeat response %v", strings.TrimSpace(string(body)))
	}

	for _ = range tick.C {
		err := heartbeatFunc()
		if err == errRegisterAgain {
			return // return so we don't run forever
		}

		if err != nil {
			k.Log.Error("couldn't sent hearbeat: %s", err)
		}
	}
}
