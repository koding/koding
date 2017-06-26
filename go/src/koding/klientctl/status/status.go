package status

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"os/exec"
	"time"

	"koding/httputil"
	"koding/klientctl/config"
	"koding/klientctl/klient"

	kodinglogging "github.com/koding/logging"
)

const waitRetry = "Please wait a moment and try again."

// KlientIsntRunning is an error printed to the user if klient is not running.
// Usually from the health checker.
var KlientIsntRunning = fmt.Sprintf(
	`Error: The %s does not appear to be running. Please run
the following command to start it:

    sudo kd start
`,
	config.KlientName,
)

// ReconnectingToKontrol is used when we have encountered specific errors pertaining
// to being disconnected from kontrol. This should be used *after* a proper health
// check, because if their internet is down, it's more meaningful than saying
// we are reconnecting to Koding.
//
// Plus, if they get no internet, and *then* reconnecting, it shows we are making
// progress in restoring functionality.
var ReconnectingToKontrol = fmt.Sprintf(
	`%s has been disconnected from Koding, and is in the process of reconnecting.
Please wait a few minutes and try again.`,
	config.Name,
)

// FailedListMachines is a generic remote.list error. We include wait a moment
// to retry, since this is often connection related.
var FailedListMachines = fmt.Sprintf(
	"Error: Failed to list machines.\n%s", waitRetry,
)

var kiteHTTPResponse = []byte("Welcome to SockJS!")

var defaultClient = httputil.NewClient(&httputil.ClientConfig{
	DialTimeout:           3 * time.Second,
	RoundTripTimeout:      3 * time.Second,
	TLSHandshakeTimeout:   3 * time.Second,
	ResponseHeaderTimeout: 3 * time.Second,
})

// HealthChecker implements state for the various HealthCheck functions,
// ideal for mocking the health check interfaces (local kite, remote http,
// remote kite, etc)
type HealthChecker struct {
	Log        kodinglogging.Logger
	HTTPClient *http.Client

	// Used for verifying a locally / remotely running kite
	LocalKlientAddress string
	KontrolAddress     string

	// eg http://t.koding.com/kite
	TunnelKiteAddress string

	// Used for verifying a working internet connection
	InternetCheckAddress string
}

func NewDefaultHealthChecker(l kodinglogging.Logger) *HealthChecker {
	return &HealthChecker{
		Log:                  l.New("HealthChecker"),
		HTTPClient:           defaultClient,
		LocalKlientAddress:   config.Konfig.Endpoints.Klient.Private.String(),
		KontrolAddress:       config.Konfig.Endpoints.Kontrol().Public.String(),
		InternetCheckAddress: config.Konfig.Endpoints.KlientLatest.Public.String(),
		TunnelKiteAddress:    config.Konfig.Endpoints.Tunnel.Public.String(),
	}
}

// ErrHealthDialFailed is used when dialing klient itself is failing. Local or remote,
// it depends on the error message.
type ErrHealthDialFailed struct{ Message string }

// ErrHealthNoHTTPReponse is used when a kite is not returning an http
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

// ErrKodingService is returned when a Koding service which KD depends upon
// (kontrol, ip check, tunneling, etc) does not appear to be operating correctly.
type ErrKodingService struct {
	Message     string
	ServiceName string
}

// ErrMissingSystemBinary is used when a binary cannot be located.
type ErrMissingSystemBinary struct {
	Message    string
	BinaryName string
}

// ErrHealthNoKontrolHTTPResponse is used when the http response from
// https://koding.com/kontrol/kite failed. Koding itself might be down, or the
// users internet might be spotty.
type ErrHealthNoKontrolHTTPResponse struct{ Message string }

func (e ErrHealthDialFailed) Error() string {
	return fmt.Sprintf("ErrHealthDialFailed: %s", e.Message)
}
func (e ErrHealthNoHTTPReponse) Error() string {
	return fmt.Sprintf("ErrHealthNoHTTPReponse: %s", e.Message)
}
func (e ErrHealthUnreadableKiteKey) Error() string {
	return fmt.Sprintf("ErrHealthUnreadableKiteKey: %s", e.Message)
}
func (e ErrHealthUnexpectedResponse) Error() string {
	return fmt.Sprintf("ErrHealthUnexpectedResponse: %s", e.Message)
}
func (e ErrHealthNoInternet) Error() string {
	return fmt.Sprintf("ErrHealthNoInternet: %s", e.Message)
}
func (e ErrHealthNoKontrolHTTPResponse) Error() string {
	return fmt.Sprintf("ErrHealthNoKontrolHTTPResponse: %s", e.Message)
}
func (e ErrKodingService) Error() string {
	return fmt.Sprintf("ErrKodingService: %s: %s", e.ServiceName, e.Message)
}
func (e ErrMissingSystemBinary) Error() string {
	return fmt.Sprintf("ErrMissingSystemBinary: %s: %s", e.BinaryName, e.Message)
}

func (c *HealthChecker) SystemRequirements() error {
	binariesToLookup := []string{"ssh", "rsync"}
	for _, bin := range binariesToLookup {
		if _, err := exec.LookPath(bin); err != nil {
			return ErrMissingSystemBinary{
				BinaryName: bin,
				Message:    err.Error(),
			}
		}
	}

	return nil
}

// CheckLocal runs several diagnostics on the local Klient. Errors
// indicate an unhealthy or not running Klient, and can be compare to
// the ErrHealth* types.
//
// TODO: Possibly return a set of warnings too? If we have any..
func (c *HealthChecker) LocalRequirements() error {
	res, err := c.HTTPClient.Get(c.LocalKlientAddress)
	// If there was an error even talking to Klient, something is wrong.
	if err != nil {
		return ErrHealthNoHTTPReponse{Message: fmt.Sprintf(
			"local klient /kite route is returning an error: %s", err,
		)}
	}
	defer res.Body.Close()

	switch res.StatusCode {
	case http.StatusOK, http.StatusNoContent:
	default:
		return ErrHealthUnexpectedResponse{Message: fmt.Sprintf(
			"unexpected status code: %d", res.StatusCode,
		)}
	}

	if res.StatusCode == http.StatusOK {
		// It should be safe to ignore any errors dumping the response data,
		// since we just want to check the data itself. Handling the error
		// might aid with debugging any problems though.
		p, err := ioutil.ReadAll(res.Body)
		if err != nil {
			return ErrHealthUnexpectedResponse{Message: fmt.Sprintf(
				"failure reading local klient /kite response: %s", err,
			)}
		}

		if bytes.Compare(kiteHTTPResponse, bytes.TrimSpace(p)) != 0 {
			return ErrHealthUnexpectedResponse{Message: fmt.Sprintf(
				"local klient /kite route is returning an unexpected response: %s", p,
			)}
		}
	}

	// The only error CreateKlientClient returns (currently) is kite read
	// error, so we can handle that.
	k, err := klient.CreateKlientWithDefaultOpts()
	if err != nil {
		return ErrHealthUnreadableKiteKey{Message: fmt.Sprintf(
			"klient kite key is unable to be read: %s", err,
		)}
	}

	// TODO: Identify varying Dial errors to produce meaningful health
	// responses.
	if err = k.Dial(); err != nil {
		return ErrHealthDialFailed{Message: fmt.Sprintf(
			"dailing local klient failed: %s", err,
		)}
	}

	return nil
}

// RemoteRequirements checks the integrity of the ability to connect
// to remote addresses, and thus verifying internet.
func (c *HealthChecker) RemoteRequirements() error {
	// Attempt to connect to google (or some reliable service) to
	// confirm the user's outbound internet connection.
	res, err := c.HTTPClient.Get(c.InternetCheckAddress)
	if err != nil {
		return ErrHealthNoInternet{Message: fmt.Sprintf(
			"http check to %q failed: %s",
			c.InternetCheckAddress, err,
		)}
	}
	defer res.Body.Close()

	// Attempt to connect to kontrol's http page, simply to get an idea
	// if Koding is running or not.
	if err := c.checkKiteHttp(c.KontrolAddress); err != nil {
		return ErrKodingService{ServiceName: "kontrol", Message: err.Error()}
	}

	return nil
}

// CheckAllExceptRunning runs local and remote checks, but ignores
// running and connectivity errors. Eg, if klient isn't running, this
// can still succeed.
//
// This is useful in the event that if klient fails to start and a health
// check is run, you don't respond with:
//
// 		We couldn't start. Reason: klient isn't running!
//
// Which is far from the best UX.
func (c *HealthChecker) CheckAllExceptRunning() (res string, ok bool) {
	// Check remote endpoints first, to debug what might be blocking Klient
	// from starting.
	if err := c.RemoteRequirements(); err != nil {
		c.Log.Warning("CheckAllExceptRunning found remote error: %s", err)
		return c.errorToMessage(err), false
	}

	if err := c.LocalRequirements(); err != nil {
		switch err.(type) {
		// Ignore dialing or bad klient http responses for CheckAllExceptRunning.
		case ErrHealthNoHTTPReponse, ErrHealthDialFailed:
		default:
			c.Log.Warning("CheckAllExceptRunning found local error: %s", err)
			return c.errorToMessage(err), false
		}
	}

	if err := c.SystemRequirements(); err != nil {
		c.Log.Warning("CheckAllExceptRunning found system requirement error: %s", err)
		return c.errorToMessage(err), false
	}

	res = fmt.Sprintf(
		"The %s appears to be running and is healthy.", config.KlientName,
	)

	return res, true
}

// CheckAllWithResponse checks local and remote, and parses the response to a
// user-friendly response. Because a response may be good or bad, a bool is also
// returned. If true, the response is good _(ie, positive, not an problem)_, and
// if it is false the response represents a problem.
func (c *HealthChecker) CheckAllWithResponse() (res string, ok bool) {
	// Check remote endpoints first, to debug what might be blocking Klient
	// from starting.
	if err := c.RemoteRequirements(); err != nil {
		c.Log.Warning("CheckAllWithResponse found remote error: %s", err)
		return c.errorToMessage(err), false
	}

	if err := c.LocalRequirements(); err != nil {
		c.Log.Warning("CheckAllWithResponse found local error: %s", err)
		return c.errorToMessage(err), false
	}

	if err := c.SystemRequirements(); err != nil {
		c.Log.Warning("CheckAllWithResponse found system requirement error: %s", err)
		return c.errorToMessage(err), false
	}

	res = fmt.Sprintf(
		"The %s appears to be running and is healthy.", config.KlientName,
	)

	return res, true
}

func (c *HealthChecker) errorToMessage(err error) (res string) {
	// Check for nil before we type match it.
	if err == nil {
		return ""
	}

	switch errType := err.(type) {
	// Remote errors
	case ErrHealthNoInternet:
		res = fmt.Sprintf(`Error: You do not appear to have a properly stable internet connection.`)

	case ErrHealthNoKontrolHTTPResponse:
		res = fmt.Sprintf(`Error: koding.com does not appear to be responding.`)

	case ErrHealthNoHTTPReponse:
		res = KlientIsntRunning

		// Local errors
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

	case ErrKodingService:
		res = fmt.Sprintf(`Error: kd is unable to connect to a required Koding service: %s

Please ensure that your local internet is stable and that Koding.com is
operating functionally for you.
`,
			errType.ServiceName,
		)

	case ErrMissingSystemBinary:
		res = fmt.Sprintf(`Error: %s is a required binary for kd to operate fully.

Please ensure that %s is installed and accessible from your system path.
`,
			errType.BinaryName, errType.BinaryName,
		)

	default:
		res = fmt.Sprintf("Unknown healthcheck error: %s", err.Error())
	}

	return res
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

// checkKiteHttp returns an error if a kite's http is not running or returning
// the expected response.
func (c *HealthChecker) checkKiteHttp(addr string) error {
	res, err := defaultClient.Get(addr)
	if err != nil {
		return fmt.Errorf("kite http request failed: %s", err)
	}

	defer res.Body.Close()

	switch res.StatusCode {
	case http.StatusOK:
		// ok - check response
	case http.StatusNoContent:
		// no content status is not an error for a kite, return nil signaling that this
		// kite is okay.
		return nil
	default:
		return fmt.Errorf("kite at %q returned unexpected code: %d", addr, res.StatusCode)
	}

	// It should be safe to ignore any errors dumping the response data,
	// since we just want to check the data itself. Handling the error
	// might aid with debugging any problems though.
	p, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return fmt.Errorf("failed to read kite response body: %s", err)
	}

	if bytes.Compare(kiteHTTPResponse, bytes.TrimSpace(p)) != 0 {
		// get a summary of the response, in case it's very large (as it might be
		// if some other webservice is running in the kite's place)
		summary := p
		if len(summary) > 50 {
			summary = summary[:50]
		}
		return fmt.Errorf("unexpected kite response: %s", summary)
	}

	return nil
}

// IsKlientRunning does a quick check against klient's http server
// to verify that it is running. It does *not* check the auth or tcp
// connection, it *just* attempts to verify that klient is running.
func IsKlientRunning(a string) bool {
	res, err := defaultClient.Get(a)
	if err != nil {
		return false
	}

	defer res.Body.Close()

	switch res.StatusCode {
	case http.StatusOK:
		// ok - check response
	case http.StatusNoContent:
		return true
	default:
		return false
	}

	// It should be safe to ignore any errors dumping the response data,
	// since we just want to check the data itself. Handling the error
	// might aid with debugging any problems though.
	p, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return false
	}

	return bytes.Compare(kiteHTTPResponse, bytes.TrimSpace(p)) == 0
}
