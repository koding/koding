package info

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"regexp"
	"time"

	"github.com/koding/klient/info/publicip"
)

// ProviderChecker funcs check the local machine to assert whether or
// not the current VM is is of that specific Provider.
type ProviderChecker func(whois string) (isProvider bool, err error)

type ProviderName int

const (
	// UnknownProvider is the zero value of the ProviderName type.
	UnknownProvider ProviderName = iota

	AWS
	Azure
	DigitalOcean
	GoogleCloud
	HPCloud
	Joylent
	Rackspace
	SoftLayer
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
	case Joylent:
		return "Joylent"
	case Rackspace:
		return "Rackspace"
	case SoftLayer:
		return "SoftLayer"
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
	AWS:          CheckAWS,
	Azure:        CheckAzure,
	DigitalOcean: CheckDigitalOcean,
	GoogleCloud:  CheckGoogleCloud,
	Joylent:      CheckJoylent,
	Rackspace:    CheckRackspace,
	SoftLayer:    CheckSoftLayer,
}

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

	return checkProvider(DefaultProviderCheckers, whois)
}

// checkProvider implements the testable functionality of CheckProvider.
// Ie, a pure func, aside from any impurities passed in via checkers.
func checkProvider(checkers map[ProviderName]ProviderChecker, whois string) (
	ProviderName, error) {

	for providerName, checker := range checkers {
		isProvider, err := checker(whois)
		if err != nil {
			return UnknownProvider, err
		}

		if isProvider == true {
			return providerName, nil
		}
	}

	return UnknownProvider, nil
}

// generateChecker returns a ProviderChecker matching one or more whois
// regexp objects against the typical ProviderChecker whois.
func generateChecker(res ...*regexp.Regexp) ProviderChecker {
	return func(whois string) (bool, error) {
		if whois == "" {
			return false, errors.New("generateChecker: Whois is required")
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
func CheckDigitalOcean(_ string) (bool, error) {
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

// CheckAWS is a generic whois checker for Amazon
var CheckAWS ProviderChecker = generateChecker(
	regexp.MustCompile(`(?i)amazon`))

var CheckAzure ProviderChecker = generateChecker(
	regexp.MustCompile(`(?i)azure`))

var CheckGoogleCloud ProviderChecker = generateChecker(
	regexp.MustCompile(`(?i)google\s*cloud`))

var CheckHPCloud ProviderChecker = generateChecker(
	regexp.MustCompile(`(?i)hp\s*cloud`))

var CheckJoylent ProviderChecker = generateChecker(
	regexp.MustCompile(`(?i)joylent`))

var CheckRackspace ProviderChecker = generateChecker(
	regexp.MustCompile(`(?i)rackspace`))

var CheckSoftLayer ProviderChecker = generateChecker(
	regexp.MustCompile(`(?i)softlayer`))

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
