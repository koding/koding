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

type ProviderName string

const (
	// The whois server WhoisQuery uses by default.
	whoisServer string = "whois.arin.net"

	// Default timeout for the whoisQuery
	whoisTimeout time.Duration = 5 * time.Second

	DigitalOcean    ProviderName = "DigitalOcean"
	UnknownProvider ProviderName = "UnknownProvider"
)

// DefaultProviderCheckers is a map of each ProviderName and the
// corresponding checker.
var DefaultProviderCheckers = map[ProviderName]ProviderChecker{
	DigitalOcean: checkDigitalOcean,
}

// CheckProvider uses the current machine's IP and runs a whois on it,
// then feeds the whois to all DefaultProviderCheckers.
func CheckProvider() (ProviderName, error) {
	// Get the IP of this machine, to whois against
	ip, err := publicip.PublicIP()
	if err != nil {
		return "", err
	}

	// Get the whois of the current vm's IP
	whois, err := WhoisQuery(ip.String(), whoisServer, whoisTimeout)
	if err != nil {
		return "", err
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
			return "", err
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

	re, err := regexp.Compile(`digitalocean\.com`)
	if err != nil {
		return false, nil
	}

	return re.MatchString(whois), nil
}

func WhoisQuery(query, server string, timeout time.Duration) (
	whois string, err error) {

	//conn, err := net.DialTimeout("tcp", "whois.arin.net:43", timeout)
	host := net.JoinHostPort(server, "43")
	conn, err := net.DialTimeout("tcp", host, timeout)
	if err != nil {
		return "", err
	}
	defer conn.Close()

	conn.Write([]byte(fmt.Sprintf("%s\r\n", query)))
	b, err := ioutil.ReadAll(conn)
	if err != nil {
		return "", err
	}

	return string(b), nil
}
