package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"koding/klientctl/config"
	"koding/klientctl/klient"
	"koding/klientctl/klientctlerrors"

	"github.com/codegangsta/cli"
	kodinglogging "github.com/koding/logging"
)

const kiteHTTPResponse = "Welcome to SockJS!\n"

var defaultHealthChecker *HealthChecker

func init() {
	defaultHealthChecker = &HealthChecker{
		HTTPClient: &http.Client{
			Timeout: 4 * time.Second,
		},
		LocalKiteAddress:  config.KlientAddress,
		RemoteKiteAddress: config.KontrolURL,
		RemoteHTTPAddress: config.S3KlientctlLatest,
	}
}

// HealthChecker implements state for the various HealthCheck functions,
// ideal for mocking the health check interfaces (local kite, remote http,
// remote kite, etc)
type HealthChecker struct {
	HTTPClient *http.Client

	// Used for verifying a locally / remotely running kite
	LocalKiteAddress  string
	RemoteKiteAddress string

	// Used for verifying a working internet connection
	RemoteHTTPAddress string
}

// ErrHealthDialFailed is used when dialing klient itself is failing. Local or remote,
// it depends on the error message.
type ErrHealthDialFailed struct{ Message string }

// ErrHealthNoHTTPReponse is used when a klient is not returning an http
// response. Local or remote, it depends on the error message.
type ErrHealthNoHTTPReponse struct{ Message string }

// ErrHealthUnreadableKiteKey is used when we are unable to read the kite.key,
// so it either doesn't exist at the specified location or the permissions are
// broken relative to the current user.
type ErrHealthUnreadableKiteKey struct{ Message string }

// ErrHealthUnexpectedResponse is used when a klient's http response on
// kiteAddress:/kite does not match the "Welcome to SockJS!" response. Local or
// remote, it depends on the error message.
type ErrHealthUnexpectedResponse struct{ Message string }

// ErrHealthNoInternet is used when the http response to a reliable endpoint
// (Google.com, for example) was unable to connect. If this is the case, the
// user is having internet troubles.
type ErrHealthNoInternet struct{ Message string }

// ErrHealthNoKontrolHTTPResponse is used when the http response from
// https://koding.com/kontrol/kite failed. Koding itself might be down, or the
// users internet might be spotty.
type ErrHealthNoKontrolHTTPResponse struct{ Message string }

func (e ErrHealthDialFailed) Error() string            { return e.Message }
func (e ErrHealthNoHTTPReponse) Error() string         { return e.Message }
func (e ErrHealthUnreadableKiteKey) Error() string     { return e.Message }
func (e ErrHealthUnexpectedResponse) Error() string    { return e.Message }
func (e ErrHealthNoInternet) Error() string            { return e.Message }
func (e ErrHealthNoKontrolHTTPResponse) Error() string { return e.Message }

// StatusCommand informs the user about the status of the Klient service. It
// does this in multiple stages, to help identify specific problems.
//
// 1. First it checks if the expected localhost http response is
// available. If it isn't, klient is not running properly or something
// else had taken the port.
//
// 2. Next, it checks if the auth is working properly, by dialing
// klient. Because we already checked if the http response was working,
// something else may be wrong. Such as the key not existing, or
// somehow kd using the wrong key, etc.
//
// 3. Lastly it checks if the user's IP has the exposed klient port. This
// is not an error because outgoing klient communication will still work,
// but incoming klient functionality will obviously be limited. So by
// checking, we can inform the user.
func StatusCommand(c *cli.Context, _ kodinglogging.Logger, _ string) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "status")
		return 1
	}

	res, ok := defaultHealthChecker.CheckAllWithResponse()
	fmt.Println(res)
	if !ok {
		return 1
	}

	return 0
}

// CheckLocal runs several diagnostics on the local Klient. Errors
// indicate an unhealthy or not running Klient, and can be compare to
// the ErrHealth* types.
//
// TODO: Possibly return a set of warnings too? If we have any..
func (c *HealthChecker) CheckLocal() error {
	res, err := c.HTTPClient.Get(c.LocalKiteAddress)
	// If there was an error even talking to Klient, something is wrong.
	if err != nil {
		return ErrHealthNoHTTPReponse{Message: fmt.Sprintf(
			"The local klient /kite route is returning an error: '%s'", err,
		)}
	}
	defer res.Body.Close()

	// It should be safe to ignore any errors dumping the response data,
	// since we just want to check the data itself. Handling the error
	// might aid with debugging any problems though.
	resData, _ := ioutil.ReadAll(res.Body)
	if string(resData) != kiteHTTPResponse {
		return ErrHealthUnexpectedResponse{Message: fmt.Sprintf(
			"The local klient /kite route is returning an unexpected response: '%s'",
			string(resData),
		)}
	}

	// The only error CreateKlientClient returns (currently) is kite read
	// error, so we can handle that.
	k, err := klient.CreateKlientWithDefaultOpts()
	if err != nil {
		return ErrHealthUnreadableKiteKey{Message: fmt.Sprintf(
			"The klient kite key is unable to be read. Reason: '%s'", err.Error(),
		)}
	}

	// TODO: Identify varing Dial errors to produce meaningful health
	// responses.
	if err = k.Dial(); err != nil {
		return ErrHealthDialFailed{Message: fmt.Sprintf(
			"Dailing local klient failed. Reason: %s", err,
		)}
	}

	return nil
}

// CheckRemote checks the integrity of the ability to connect
// to remote addresses, and thus verifying internet.
func (c *HealthChecker) CheckRemote() error {
	// Attempt to connect to google (or some reliable service) to
	// confirm the user's outbound internet connection.
	res, err := c.HTTPClient.Get(c.RemoteHTTPAddress)
	if err != nil {
		return ErrHealthNoInternet{Message: fmt.Sprintf(
			"The internet connection fails to '%s'. Reason: %s",
			c.RemoteHTTPAddress, err.Error(),
		)}
	}
	defer res.Body.Close()

	// Attempt to connect to kontrol's http page, simply to get an idea
	// if Koding is running or not.
	res, err = c.HTTPClient.Get(c.RemoteKiteAddress)
	if err != nil {
		return ErrHealthNoKontrolHTTPResponse{Message: fmt.Sprintf(
			"A http request to Kontrol failed. Reason: %s", err.Error(),
		)}
	}
	defer res.Body.Close()

	// Kontrol should return a 200 response.
	if res.StatusCode < 200 || res.StatusCode > 299 {
		return ErrHealthNoKontrolHTTPResponse{Message: fmt.Sprintf(
			"A http request to Kontrol returned bad status code. Code: %d",
			res.StatusCode,
		)}
	}

	// It should be safe to ignore any errors dumping the response data,
	// since we just want to check the data itself. Handling the error
	// might aid with debugging any problems though.
	//
	// TODO: Log the response if it's not as expected, to help
	// debug Cloudflare/nginx issues.
	resData, _ := ioutil.ReadAll(res.Body)
	if string(resData) != kiteHTTPResponse {
		return ErrHealthUnexpectedResponse{Message: fmt.Sprintf(
			"The '%s' route is returning an unexpected response: '%s'",
			c.RemoteKiteAddress, string(resData),
		)}
	}

	// TODO: Check the local ip address for an open port. We
	// need to implement a service on Koding to properly ip check though,
	// since we've been having problems with echoip.net failing.

	return nil
}

// CheckAllWithResponse checks local and remote, and parses the response to a
// user-friendly response. Because a response may be good or bad, a bool is also
// returned. If true, the response is good _(ie, positive, not an problem)_, and
// if it is false the response represents a problem.
//
// TODO: Enable debug logs
// log.Print(err.Error())
func (c *HealthChecker) CheckAllWithResponse() (res string, ok bool) {
	if err := defaultHealthChecker.CheckLocal(); err != nil {
		switch err.(type) {
		case ErrHealthNoHTTPReponse:
			res = KlientIsntRunning

		case ErrHealthUnexpectedResponse:
			res = fmt.Sprintf(`Error: The %s is not running properly. Please run the
following command to restart it:

    sudo kd restart
`,
				config.KlientName)

		case ErrHealthUnreadableKiteKey:
			res = fmt.Sprintf(`Error: The authorization file for the %s is malformed
or missing. Please run the following command:

    sudo kd install
`,
				config.KlientName)

		// TODO: What are some good steps for the user to take if dial fails?
		case ErrHealthDialFailed:
			res = fmt.Sprintf(`Error: The %s does not appear to be running properly.
Please run the following command:

    sudo kd restart
`,
				config.KlientName)

		default:
			res = fmt.Sprintf("Unknown local healthcheck error: %s", err.Error())
		}

		return res, false
	}

	if err := defaultHealthChecker.CheckRemote(); err != nil {
		switch err.(type) {
		case ErrHealthNoInternet:
			res = fmt.Sprintf(`Error: You do not appear to have a properly working internet connection.`)

		case ErrHealthNoKontrolHTTPResponse:
			res = fmt.Sprintf(`Error: koding.com does not appear to be responding.`)

		default:
			res = fmt.Sprintf("Unknown remote healthcheck error: %s", err.Error())
		}

		return res, false
	}

	res = fmt.Sprintf(
		"The %s appears to be running and is healthy.", config.KlientName,
	)

	return res, true
}

// CheckAllFailureOrMessagef runs CheckAllWithResponse and if there is a failure,
// returns that status message. If CheckAllWithResponse returns ok, the formatted
// message is returned. This *does not* print success messages.
//
// This is a shorthand for informing the user about an error. There already was an
// error, we're just trying to inform the user what it was about. For comparison,
// here is the syntax that this method provides:
//
//     fmt.Println(defaultHealthChecker.FailureResponseOrMessagef(
//       "Error connecting to %s: '%s'\n", config.KlientName, err,
//     ))
//
// And here is the syntax we're avoiding:
//
//     s, ok := defaultHealthChecker.CheckAllWithResponse()
//     if ok {
//       fmt.Printf("Error connecting to %s: '%s'\n", config.KlientName, err)
//     } else {
//       fmt.Println(s)
//     }
func (c *HealthChecker) CheckAllFailureOrMessagef(f string, i ...interface{}) string {
	if s, ok := c.CheckAllWithResponse(); !ok {
		return s
	}

	return fmt.Sprintf(f, i...)
}

// IsKlientRunning does a quick check against klient's http server
// to verify that it is running. It does *not* check the auth or tcp
// connection, it *just* attempts to verify that klient is running.
func IsKlientRunning(a string) bool {
	res, err := http.Get(a)

	if res != nil {
		defer res.Body.Close()
	}

	// If there was an error even talking to Klient, something is wrong.
	if err != nil {
		return false
	}

	// It should be safe to ignore any errors dumping the response data,
	// since we just want to check the data itself. Handling the error
	// might aid with debugging any problems though.
	resData, _ := ioutil.ReadAll(res.Body)
	if string(resData) != kiteHTTPResponse {
		return false
	}

	return true
}

func getListErrRes(err error, healthChecker *HealthChecker) string {
	res, ok := defaultHealthChecker.CheckAllWithResponse()

	// If the health check response is not okay, return that because it's likely
	// more informed (such as no internet, etc)
	if !ok {
		return res
	}

	// Because healthChecker couldn't find anything wrong, but we know there is an
	// err, check to see if it's a getKites err
	if klientctlerrors.IsListReconnectingErr(err) {
		return ReconnectingToKontrol
	}

	return FailedListMachines
}
