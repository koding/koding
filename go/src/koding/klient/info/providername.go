package info

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"regexp"
	"time"

	"koding/klient/info/publicip"
)

const (
	// The whois server WhoisQuery uses by default.
	whoisServer string = "whois.arin.net"

	// Default timeout for the whoisQuery
	whoisTimeout time.Duration = 5 * time.Second
)

// ProviderChecker funcs check the local machine to assert whether or
// not the current VM is is of that specific Provider.
type ProviderChecker func() (isProvider bool, err error)

// WhoisFunc returns the whois from the whois protocol.
type WhoisFunc func() (whois string, err error)

type ProviderName int

const (
	// UnknownProvider is the zero value of the ProviderName type.
	UnknownProvider ProviderName = iota

	AWS
	Azure
	DigitalOcean
	GoogleCloud
	HPCloud
	Joyent
	Rackspace
	SoftLayer
	Koding
)

func (pn ProviderName) String() string {
	switch pn {
	case AWS:
		return "AWS"
	case Azure:
		return "Azure"
	case DigitalOcean:
		return "DigitalOcean"
	case GoogleCloud:
		return "GoogleCloud"
	case HPCloud:
		return "HPCloud"
	case Joyent:
		return "Joyent"
	case Rackspace:
		return "Rackspace"
	case SoftLayer:
		return "SoftLayer"
	case Koding:
		return "Koding"
	default:
		return "UnknownProvider"
	}
}

// Checker returns the ProviderChecker for the given ProviderName
func (pn ProviderName) Checker() ProviderChecker {
	switch pn {
	case AWS:
		return CheckAWS
	case Azure:
		return CheckAzure
	case DigitalOcean:
		return CheckDigitalOcean
	case GoogleCloud:
		return CheckGoogleCloud
	case Joyent:
		return CheckJoyent
	case Rackspace:
		return CheckRackspace
	case SoftLayer:
		return CheckSoftLayer
	case Koding:
		return CheckKoding
	default:
		return nil
	}
}

// DefaultProviderCheckers is a slice of each ProviderName in the order
// that they will be checked.
var DefaultProvidersToCheck = []ProviderName{
	DigitalOcean,
	Koding,
	AWS,
	Azure,
	GoogleCloud,
	Joyent,
	Rackspace,
	SoftLayer,
}

// cachedProviderName is the ProviderName resulting from running through
// all of the DefaultProviderCheckers.
//
// This should not be written to by anyone but CheckProvider(), because
// an individual ProviderChecker may not be correct when compared to
// CheckProvider. For example, CheckAWS() will always return true, even
// if the ProviderName is actually Koding.
//
// ProviderCheckers are able to read from this value though, if desired.
var cachedProviderName ProviderName

// CheckProvider uses the current machine's IP and runs a whois on it, then
// feeds the whois to all DefaultProviderCheckers. Providers are free to use
// the whois query.
func CheckProvider() (ProviderName, error) {
	if cachedProviderName != UnknownProvider {
		return cachedProviderName, nil
	}

	providerName, err := checkProvider(DefaultProvidersToCheck)
	if err != nil {
		return UnknownProvider, err
	}

	cachedProviderName = providerName

	return providerName, nil
}

// checkProvider implements the testable functionality of CheckProvider.
// Ie, a pure func, aside from any impurities passed in via checkers.
func checkProvider(providers []ProviderName) (ProviderName, error) {
	for _, providerName := range providers {
		checker := providerName.Checker()
		if checker == nil {
			return UnknownProvider, errors.New(fmt.Sprintf(
				"checkProvider: No checker for ProviderName '%s'",
				providerName.String(),
			))
		}

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

// generateWhoisChecker returns a ProviderChecker matching one or more whois
// regexp objects against the typical ProviderChecker whois.
func generateWhoisChecker(provider ProviderName, res ...*regexp.Regexp) ProviderChecker {
	return func() (bool, error) {
		if cachedProviderName == provider {
			return true, nil
		}

		whois, err := DefaultWhoisChecker()
		if err != nil {
			return false, err
		}

		for _, re := range res {
			if !re.MatchString(whois) {
				return false, nil
			}
		}

		return true, nil
	}
}

// CheckDigitalOcean is a ProviderChecker for DigitalOcean
func CheckDigitalOcean() (bool, error) {
	if cachedProviderName == DigitalOcean {
		return true, nil
	}

	return checkDigitalOcean("http://169.254.169.254/metadata/v1/hostname")
}

// checkDigitalOcean implements the testable functionality of
// CheckDigitalOcean by quering the given DigitalOcean API address
// and if it returns 404, the check fails.
func checkDigitalOcean(metadataApi string) (bool, error) {
	res, err := http.Get(metadataApi)

	// An error during the http request indicates that the API server
	// is either non-existent, or does not exist. This is expected
	// behavior if this func is called on something other than DigitalOcean,
	// and should not return an error.
	//
	// Note: It's also possible that the given string is not a valid URL,
	// but we're not worrying about that since this is a private func.
	// If we want to handle that, we should simply create a net.URL and
	// return any parsing errors from that, and not from http.Get()
	if err != nil {
		return false, nil
	}

	return res.StatusCode == http.StatusOK, nil
}

// CheckAWS is a generic whois checker for Amazon
var CheckAWS ProviderChecker = generateWhoisChecker(
	AWS,
	regexp.MustCompile(`(?i)amazon`),
)

var CheckAzure ProviderChecker = generateWhoisChecker(
	Azure,
	regexp.MustCompile(`(?i)azure`),
)

var CheckGoogleCloud ProviderChecker = generateWhoisChecker(
	GoogleCloud,
	regexp.MustCompile(`(?i)google\s*cloud`),
)

var CheckHPCloud ProviderChecker = generateWhoisChecker(
	HPCloud,
	regexp.MustCompile(`(?i)hp\s*cloud`),
)

var CheckJoyent ProviderChecker = generateWhoisChecker(
	Joyent,
	regexp.MustCompile(`(?i)joyent`),
)

var CheckRackspace ProviderChecker = generateWhoisChecker(
	Rackspace,
	regexp.MustCompile(`(?i)rackspace`),
)

var CheckSoftLayer ProviderChecker = generateWhoisChecker(
	SoftLayer,
	regexp.MustCompile(`(?i)softlayer`),
)

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

// DefaultWhoisChecker is used for all whois based checkers
var DefaultWhoisChecker WhoisFunc = func() (string, error) {
	// Get the IP of this machine, to whois against
	ip, err := publicip.PublicIP()
	if err != nil {
		return "", err
	}

	// Get the whois of the current vm's IP
	return WhoisQuery(ip.String(), whoisServer, whoisTimeout)
}
