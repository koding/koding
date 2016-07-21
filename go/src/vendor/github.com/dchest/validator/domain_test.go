// Copyright 2013 Dmitry Chestnykh. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package validator

import (
	"testing"
)

// Validation tests.

var validDomains = []string{
	"www.codingrobots.com",
	"google.com",
	"sub.domain.example.com",
	"another.valid.com.",
}

var invalidDomains = []string{
	"",
	"local",
	".example.com",
	"президент.рф", // must be in IDNA encoded form
	"invalid..",
}

func TestIsValidDomain(t *testing.T) {
	for i, v := range validDomains {
		if !IsValidDomain(v) {
			t.Errorf("%d: didn't accept valid domain: %s", i, v)
		}
	}
	for i, v := range invalidDomains {
		if IsValidDomain(v) {
			t.Errorf("%d: accepted invalid domain: %s", i, v)
		}
	}
}

func TestValidateDomainByResolvingIt(t *testing.T) {
	err := ValidateDomainByResolvingIt("www.example.com")
	if err != nil {
		t.Errorf("%s", err)
	}
	err = ValidateDomainByResolvingIt("randomdomainnamethatdoesntexist")
	if err == nil {
		t.Errorf("invalid domain name validated")
	}
}

// Normalization tests.

var sameDomains = []string{
	"www.example.com",
	"www.EXAMPLE.COM",
	"www.example.com.",
	"WWW.exampLE.CoM",
}

var differentDomains = []string{
	"www.example.com",
	"example.com",
}

func TestNormalizeDomain(t *testing.T) {
	for i, v0 := range sameDomains {
		for j, v1 := range sameDomains {
			if i == j {
				continue
			}
			nv0 := NormalizeDomain(v0)
			nv1 := NormalizeDomain(v1)
			if nv0 == "" {
				t.Errorf("%d: domain invalid: %q", i, v0)
			}
			if nv0 != nv1 {
				t.Errorf("%d-%d: normalized domains differ: %q and %q", i, j, nv0, nv1)
			}
		}
	}
	for i, v0 := range differentDomains {
		for j, v1 := range differentDomains {
			if i == j {
				continue
			}
			nv0 := NormalizeDomain(v0)
			nv1 := NormalizeDomain(v1)
			if nv0 == "" {
				t.Errorf("%d: domain invalid: %q", i, v0)
			}
			if nv0 == nv1 {
				t.Errorf("%d-%d: normalized domains are the same: %q and %q", i, j, nv0, nv1)
			}
		}
	}
}
