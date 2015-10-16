package main

import (
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/codegangsta/cli"
)

// Dialing klient itself is failing. This likely shouldn't happen, but
// it is in theory possible for invalid auth or if simply klient is
// not running properly.
type HealthErrorDialFailed struct{ Message string }

// The local klient is not returning an http response.
type HealthErrorNoHttp struct{ Message string }

// We are unable to Read the kite.key, so it either doesn't exist at the
// specified location or the permissions are broken relative to the
// current user.
type HealthErrorUnableReadKey struct{ Message string }

// The http response on /kite does not match the "Welcome to SockJS!"
// klient response.
type HealthErrorUnexpectedResponse struct{ Message string }

// The http response to a reliable endpoint (Google.com, for example)
// was unable to connect. If this is the case, the user is having internet
// troubles.
type HealthErrorNoInternet struct{ Message string }

// The http response from https://koding.com/kontrol/kite failed. Koding
// itself might be down, or the users internet might be spotty.
type HealthErrorNoKontrolHttp struct{ Message string }

func (e HealthErrorDialFailed) Error() string         { return e.Message }
func (e HealthErrorNoHttp) Error() string             { return e.Message }
func (e HealthErrorUnableReadKey) Error() string      { return e.Message }
func (e HealthErrorUnexpectedResponse) Error() string { return e.Message }
func (e HealthErrorNoInternet) Error() string         { return e.Message }
func (e HealthErrorNoKontrolHttp) Error() string      { return e.Message }

// Status informs the user about the status of the Klient service. It
// does this in multiple stages, to help identify specific problems.
//
// 1. First it checks if the expected localhost http response is
// 	available. If it isn't, klient is not running properly or something
// 	else had taken the port.
//
// 2. Next, it checks if the auth is working properly, by dialing
// 	klient. Because we already checked if the http response was working,
// 	something else may be wrong. Such as the key not existing, or
// 	somehow kd using the wrong key, etc.
//
// 3. Lastly it checks if the user's IP has the exposed klient port. This
// 	is not an error because outgoing klient communication will still work,
// 	but incoming klient functionality will obviously be limited. So by
// 	checking, we can inform the user.
func StatusCommand(c *cli.Context) int {
	err := HealthCheckLocal(KlientAddress)
	if err != nil {
		// TODO: Enable debug logs
		// log.Print(err.Error())

		// Print a friendly message for each of the given health responses.
		switch err.(type) {
		case HealthErrorNoHttp:
			fmt.Printf(
				`Error: The %s does not appear to be running. Please run
the following command to start it:

    sudo kd start
`,
				KlientName)

		case HealthErrorUnexpectedResponse:
			fmt.Printf(`Error: The %s is not running properly. Please run the
following command to restart it:

    sudo kd restart
`,
				KlientName)

		case HealthErrorUnableReadKey:
			fmt.Printf(`Error: The authorization file for the %s is malformed
or missing. Please run the following command:

    sudo kd install
`,
				KlientName)

		// TODO: What are some good steps for the user to take if dial fails?
		case HealthErrorDialFailed:
			fmt.Printf(`Error: The %s does not appear to be running properly.
Please run the following command:

    sudo kd restart
`,
				KlientName)

		default:
			fmt.Println("Unknown local healthcheck error:", err.Error())
		}

		return 1
	}

	err = HealthCheckRemote("https://google.com", "https://koding.com/kontrol/kite")

	if err != nil {
		// TODO: Enable debug logs
		// log.Print(err.Error())

		// Print a friendly message for each of the given health responses.
		switch err.(type) {
		case HealthErrorNoInternet:
			fmt.Println(`Error: You do not appear to have a properly working internet connection.`)

		case HealthErrorNoKontrolHttp:
			fmt.Printf(`Error: Koding.com does not appear to be responding.
If this problem persists, please contact us at: support@koding.com
`)

		default:
			fmt.Println("Unknown remote healthcheck error:", err.Error())
		}

		return 1
	}

	fmt.Printf("The %s appears to be running and is healthy\n",
		KlientName)

	return 0
}

// HealthCheck runs several diagnostics on the local Klient. Errors
// indicate an unhealthy or not running Klient, and can be compare to
// the HealthError* types.
//
// TODO: Possibly return a set of warnings too? If we have any..
func HealthCheckLocal(a string) error {
	res, err := http.Get(a)
	// If there was an error even talking to Klient, something is wrong.
	if err != nil {
		return HealthErrorNoHttp{Message: fmt.Sprintf(
			"The klient /kite route is returning an error: '%s'", err.Error(),
		)}
	}
	defer res.Body.Close()

	// It should be safe to ignore any errors dumping the response data,
	// since we just want to check the data itself. Handling the error
	// might aid with debugging any problems though.
	resData, _ := ioutil.ReadAll(res.Body)
	if string(resData) != "Welcome to SockJS!\n" {
		return HealthErrorUnexpectedResponse{Message: fmt.Sprintf(
			"The klient /kite route is returning an unexpected response: '%s'",
			string(resData),
		)}
	}

	// The only error CreateKlientClient returns (currently) is kite read
	// error, so we can handle that.
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		return HealthErrorUnableReadKey{Message: fmt.Sprintf(
			"The klient kite key is unable to be read. Reason: '%s'", err.Error(),
		)}
	}

	// TODO: Identify varing Dial errors to produce meaningful health
	// responses.
	if err = k.Dial(); err != nil {
		return HealthErrorDialFailed{Message: fmt.Sprintf(
			"Dailing klient failed. Reason:", err.Error(),
		)}
	}

	return nil
}

// HealthCheckRemote checks the integrity of the ability to connect
// to remote addresses, and thus verifying internet.
func HealthCheckRemote(inetAddress, kontrolAddress string) error {
	// Attempt to connect to google (or some reliable service) to
	// confirm the user's outbound internet connection.
	res, err := http.Get(inetAddress)
	if err != nil {
		return HealthErrorNoInternet{Message: fmt.Sprintf(
			"The internet connection fails to '%s'. Reason: %s",
			inetAddress, err.Error(),
		)}
	}
	defer res.Body.Close()

	// Attempt to connect to kontrol's http page, simply to get an idea
	// if Koding is running or not.
	res, err = http.Get(kontrolAddress)
	if err != nil {
		return HealthErrorNoKontrolHttp{Message: fmt.Sprintf(
			"A http request to Kontrol failed. Reason: %s", err.Error(),
		)}
	}
	defer res.Body.Close()

	// Kontrol should return a 200 response.
	if res.StatusCode < 200 || res.StatusCode > 299 {
		return HealthErrorNoKontrolHttp{Message: fmt.Sprintf(
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
	if string(resData) != "Welcome to SockJS!\n" {
		return HealthErrorUnexpectedResponse{Message: fmt.Sprintf(
			"The '%s' route is returning an unexpected response: '%s'",
			kontrolAddress, string(resData),
		)}
	}

	// TODO: Check the local ip address for an open port. We
	// need to implement a service on Koding to properly ip check though,
	// since we've been having problems with echoip.net failing.

	return nil
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
	if string(resData) != "Welcome to SockJS!\n" {
		return false
	}

	return true
}
