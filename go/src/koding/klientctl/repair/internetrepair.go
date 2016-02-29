package repair

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

// DefaultInternetHTTP is a slice of default sites to check if we have internet.
var DefaultInternetConfirmAddrs = []string{
	"http://echoip.com",
	"http://api.ipify.org",
	"http://ipinfo.io/ip",
}

// InternetRepair checks a list of http endpoints, and if any of them come up as
// working then the user has internet.
//
// Unlike most other Repairers, this repairer doesn't actually take any action
// and will simply fail if there is no internet.
type InternetRepair struct {
	// The slice of http endpoints that we check to verify if the internet is working
	// or not. We check multiple, to avoid false "no internet" reports.
	InternetConfirmAddrs []string

	// The http timeout to use on requests
	HTTPTimeout time.Duration

	// The options that this repairer will use.
	RetryOpts RetryOptions

	// The way
	Stdout io.Writer
}

func (r *InternetRepair) String() string {
	return "internetrepair"
}

// Status simply loops through each of the http endpoints until one of them succeed,
// or they all fail.
func (r *InternetRepair) Status() (bool, error) {
	var (
		ok  bool
		err error
	)

	for i := uint(0); i <= r.RetryOpts.StatusRetries; i++ {
		ok, err = r.status()
		if ok {
			break
		}

		switch i {
		case 0:
			fmt.Fprint(r.Stdout, "Internet appears to be down. Waiting for reconnect.")
		default:
			fmt.Fprint(r.Stdout, " .")
		}

		time.Sleep(r.RetryOpts.StatusDelay)
	}

	fmt.Fprint(r.Stdout, "\n")

	return ok, err
}

// status implements the non-repeating logic of Status
func (r *InternetRepair) status() (bool, error) {
	// If we have no http endpoints, we can't verify the internet is working.
	if len(r.InternetConfirmAddrs) == 0 {
		return false, errors.New("No http addresses available to check")
	}

	client := &http.Client{
		Timeout: r.HTTPTimeout,
	}

	var (
		res *http.Response
		err error
	)

	for _, addr := range r.InternetConfirmAddrs {
		res, err = client.Get(addr)

		if res != nil {
			res.Body.Close()
		}

		if err == nil {
			return true, nil
		}
	}

	return false, err
}

// Repair returns an error, because we cannot actually fix the internet. Instead
// of using repair, you should set a high StatusRetry value, to wait until Status
// succeeds.
func (r *InternetRepair) Repair() error {
	fmt.Fprintln(r.Stdout, "Error: Unable to repair internet.")
	return errors.New("Unable to Repair internet")
}
