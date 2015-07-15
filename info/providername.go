package info

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"regexp"
	"time"
)

// ProviderChecker funcs check the local machine to assert whether or
// not the current VM is is of that specific Provider.
type ProviderChecker func() (isProvider bool, err error)

type ProviderName int

const (
	// UnknownProvider is the zero value of the ProviderName type.
	UnknownProvider ProviderName = iota

	// A DigitalOcean virtual machine
	DigitalOcean
)

func (pn ProviderName) String() string {
	switch pn {
	case DigitalOcean:
		return "DigitalOcean"
	default:
		return "UnknownProvider"
	}
}

const (
	// The whois server WhoisQuery uses by default.
	whoisServer string = "whois.arin.net"

	// Default timeout for the whoisQuery
	whoisTimeout time.Duration = 5 * time.Second
)

// DefaultProviderCheckers is a map of each ProviderName and the
// corresponding checker.
var DefaultProviderCheckers = map[ProviderName]ProviderChecker{
	DigitalOcean: CheckDigitalOcean,
}

// digitalOceanRegexp is used to verify a whois string which belongs
// to DigitalOcean.
var digitalOceanRegexp = regexp.MustCompile(`digitalocean\.com`)

// CheckProvider uses the current machine's IP and runs a whois on it,
// then feeds the whois to all DefaultProviderCheckers.
func CheckProvider() (ProviderName, error) {
	return checkProvider(DefaultProviderCheckers)
}

// checkProvider implements the testable functionality of CheckProvider.
// Ie, a pure func, aside from any impurities passed in via checkers.
func checkProvider(checkers map[ProviderName]ProviderChecker) (
	ProviderName, error) {

	for providerName, checker := range checkers {
		isProvider, err := checker()
		if err != nil {
			return UnknownProvider, err
		}

		if isProvider == true {
			return providerName, nil
		}
	}

	return UnknownProvider, nil
}

// CheckDigitalOcean is a ProviderChecker for DigitalOcean
func CheckDigitalOcean() (bool, error) {
	return checkDigitalOcean("http://169.254.169.254/metadata/v1/hostname")
}

// checkDigitalOcean implements the testable functionality of
// CheckDigitalOcean by quering the given DigitalOcean API address
// and if it returns 404, the check fails.
func checkDigitalOcean(metadataApi string) (bool, error) {
	res, err := http.Get(metadataApi)
	if err != nil {
		return false, err
	}

	return res.StatusCode == http.StatusOK, nil
}

// WhoisQuery is a simple func to query a whois service with the (limited)
// whois protocol.
//
// It's worth noting that because the whois protocol is so basic, the
// response can be formatted in any way. Because of this, WhoisQuery has to
// simply return the entire response to the caller - and is unable to
// marshall/etc the response in any meaningful format.
func WhoisQuery(query, server string, timeout time.Duration) (string, error) {
	host := net.JoinHostPort(server, "43")
	conn, err := net.DialTimeout("tcp", host, timeout)
	if err != nil {
		return "", err
	}
	defer conn.Close()

	// Query the whois server with the ip or domain given to this func,
	// as per Whois spec.
	_, err = conn.Write([]byte(fmt.Sprintf("%s\r\n", query)))
	if err != nil {
		return "", err
	}

	// After the query, the server will respond with the unformatted data.
	// Read it all and return it.
	b, err := ioutil.ReadAll(conn)
	if err != nil {
		return "", err
	}

	return string(b), nil
}
