package main

import (
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/codegangsta/cli"
)

// TODO: Make custom error types, so that we can provide custom
// error messages while still retaining easily identiable errors?
var (
//	// The local klient is not returning an http response.
//	HealthErrorNoHttp = errors.New(
//		"The klient /kite route is returning an error")
//
//	// The http response on /kite does not match the "Welcome to SockJS!"
//	// klient response.
//	HealthErrorUnexpectedResponse = errors.New(
//		"The klient /kite route is not returning the expected response")
)

type HealthErrorDialFailed struct{ Message string }
type HealthErrorNoHttp struct{ Message string }
type HealthErrorUnableReadKey struct{ Message string }
type HealthErrorUnexpectedResponse struct{ Message string }

func (e HealthErrorDialFailed) Error() string         { return e.Message }
func (e HealthErrorNoHttp) Error() string             { return e.Message }
func (e HealthErrorUnableReadKey) Error() string      { return e.Message }
func (e HealthErrorUnexpectedResponse) Error() string { return e.Message }

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
	err := HealthCheck(KlientAddress)

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
			fmt.Println("Unknown healthcheck error:", err.Error())
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
func HealthCheck(a string) error {
	res, err := http.Get(a)
	if res != nil {
		defer res.Body.Close()
	}

	// If there was an error even talking to Klient, something is wrong.
	if err != nil {
		return HealthErrorNoHttp{Message: fmt.Sprintf(
			"The klient /kite route is returning an error: '%s'", err.Error(),
		)}
	}

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
