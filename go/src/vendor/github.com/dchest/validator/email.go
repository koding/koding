// Copyright 2013 Dmitry Chestnykh. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package validator validates and normalizes email addresses and domain names.
package validator

import (
	"errors"
	"net"
	"regexp"
	"strings"
)

// Regular expression from WebCore's HTML5 email input: http://goo.gl/7SZbzj
var emailRegexp = regexp.MustCompile("(?i)" + // case insensitive
	"^[a-z0-9!#$%&'*+/=?^_`{|}~.-]+" + // local part
	"@" +
	"[a-z0-9-]+(\\.[a-z0-9-]+)*$") // domain part

// IsValidEmail returns true if the given string is a valid email address.
//
// It uses a simple regular expression to check the address validity.
func IsValidEmail(email string) bool {
	if len(email) > 254 {
		return false
	}
	return emailRegexp.MatchString(email)
}

var ErrInvalidEmail = errors.New("invalid email address")

// fetchMXRecords fetches MX records for the domain of the given email.
func fetchMXRecords(email string) ([]*net.MX, error) {
	if !IsValidEmail(email) {
		return nil, ErrInvalidEmail
	}
	// Extract domain.
	_, domain, ok := splitEmail(email)
	if !ok {
		return nil, ErrInvalidEmail
	}
	if !IsValidDomain(domain) {
		return nil, ErrInvalidEmail
	}
	mx, err := net.LookupMX(domain)
	if err != nil {
		return nil, err
	}
	return mx, nil
}

// ValidateEmailByResolvingDomain validates email address by looking up MX
// records on its domain.
//
// This function can return various DNS errors, which may be temporary
// (e.g. caused by internet connection being offline) or permanent,
// e.g. the host doesn't exist or has no MX records.
//
// The function returns nil if email is valid and its domain can
// accept email messages (however this doesn't guarantee that a user
// with such email address exists on the host).
func ValidateEmailByResolvingDomain(email string) error {
	mx, err := fetchMXRecords(email)
	if err != nil {
		return err
	}
	if len(mx) == 0 {
		return ErrInvalidEmail
	}
	return nil
}

// splitEmail splits email address into local and domain parts.
// The last returned value is false if splitting fails.
func splitEmail(email string) (local string, domain string, ok bool) {
	parts := strings.Split(email, "@")
	if len(parts) < 2 {
		return
	}
	local = parts[0]
	domain = parts[1]
	// Check that the parts contain enough characters.
	if len(local) < 1 {
		return
	}
	if len(domain) < len("x.xx") {
		return
	}
	return local, domain, true
}

// NormalizeEmail returns a normalized email address.
// It returns an empty string if the email is not valid.
func NormalizeEmail(email string) string {
	// Trim whitespace.
	email = strings.TrimSpace(email)
	// Make sure it is valid.
	if !IsValidEmail(email) {
		return ""
	}
	// Split email into parts.
	local, domain, ok := splitEmail(email)
	if !ok {
		return ""
	}
	// Remove trailing dot from domain.
	domain = strings.TrimRight(domain, ".")
	// Convert domain to lower case.
	domain = strings.ToLower(domain)
	// Combine and return the result.
	return local + "@" + domain
}
