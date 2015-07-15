package info

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"regexp"
	"time"

	"github.com/koding/klient/info/publicip"
)

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
	DigitalOcean: checkDigitalOcean,
}

// digitalOceanRegexp is used to verify a whois string which belongs
// to DigitalOcean.
var digitalOceanRegexp = regexp.MustCompile(`digitalocean\.com`)

// CheckProvider uses the current machine's IP and runs a whois on it,
// then feeds the whois to all DefaultProviderCheckers.
func CheckProvider() (ProviderName, error) {
	// Get the IP of this machine, to whois against
	ip, err := publicip.PublicIP()
	if err != nil {
		return UnknownProvider, err
	}

	// Get the whois of the current vm's IP
	whois, err := WhoisQuery(ip.String(), whoisServer, whoisTimeout)
	if err != nil {
		return UnknownProvider, err
	}

	return checkProvider(whois, DefaultProviderCheckers)
}

// checkProvider implements the testable functionality of CheckProvider.
// Ie, a pure func, aside from any impurities passed in via checkers.
func checkProvider(whois string,
	checkers map[ProviderName]ProviderChecker) (ProviderName, error) {

	var isProvider bool
	var err error
	for providerName, checker := range checkers {
		isProvider, err = checker(whois)
		if err != nil {
			return UnknownProvider, err
		}

		if isProvider == true {
			return providerName, nil
		}
	}

	return UnknownProvider, nil
}

// ProviderChecker funcs check the given information, and whatever else
// they desire, to assert whether or not the current VM is belongs
// to them or not.
type ProviderChecker func(whois string) (isProvider bool, err error)

// checkDigitalOcean is a ProviderChecker which parses the given whois
// string and checks if the whois is owned by DigitalOcean.
func checkDigitalOcean(whois string) (bool, error) {
	if whois == "" {
		return false, errors.New("checkDigitalOcean: Whois is required")
	}

	return digitalOceanRegexp.MatchString(whois), nil
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
