package validator

import (
	"errors"
	"net"
	"regexp"
	"strings"
)

var domainRegexp = regexp.MustCompile(`^(?i)[a-z0-9-]+(\.[a-z0-9-]+)+\.?$`)

// IsValidDomain returns true if the domain is valid.
//
// It uses a simple regular expression to check the domain validity.
func IsValidDomain(domain string) bool {
	return domainRegexp.MatchString(domain)
}

var ErrInvalidDomain = errors.New("invalid domain")

// ValidateDomainByResolvingIt queries DNS for the given domain name,
// and returns nil if the the name resolves, or an error.
func ValidateDomainByResolvingIt(domain string) error {
	if !IsValidDomain(domain) {
		return ErrInvalidDomain
	}
	addr, err := net.LookupHost(domain)
	if err != nil {
		return err
	}
	if len(addr) == 0 {
		return ErrInvalidDomain
	}
	return nil
}

// NormalizeEmail returns a normalized domain.
// It returns an empty string if the domain is not valid.
func NormalizeDomain(domain string) string {
	// Trim whitespace.
	domain = strings.TrimSpace(domain)
	// Check validity.
	if !IsValidDomain(domain) {
		return ""
	}
	// Remove trailing dot.
	domain = strings.TrimRight(domain, ".")
	// Convert to lower case.
	domain = strings.ToLower(domain)
	return domain
}
