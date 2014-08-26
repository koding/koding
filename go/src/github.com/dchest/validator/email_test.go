// Copyright 2013 Dmitry Chestnykh. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package validator

import (
	"testing"
)

// Validation tests.

var validEmails = []string{
	"a@example.com",
	"postmaster@example.com",
	"president@kremlin.gov.ru",
	"example@example.co.uk",
}

var invalidEmails = []string{
	"",
	"example",
	"example.com",
	".com",
	"адрес@пример.рф",
	" space_before@example.com",
	"space between@example.com",
	"\nnewlinebefore@example.com",
	"newline\nbetween@example.com",
	"test@example.com.",
	"asyouallcanseethisemailaddressexceedsthemaximumnumberofcharactersallowedtobeintheemailaddresswhichisnomorethatn254accordingtovariousrfcokaycanistopnowornotyetnoineedmorecharacterstoadd@i.really.cannot.thinkof.what.else.to.put.into.this.invalid.address.net",
}

func TestIsValidEmail(t *testing.T) {
	for i, v := range validEmails {
		if !IsValidEmail(v) {
			t.Errorf("%d: didn't accept valid email: %s", i, v)
		}
	}
	for i, v := range invalidEmails {
		if IsValidEmail(v) {
			t.Errorf("%d: accepted invalid email: %s", i, v)
		}
	}
}

func TestValidateEmailByResolvingDomain(t *testing.T) {
	err := ValidateEmailByResolvingDomain("abuse@gmail.com")
	if err != nil {
		t.Errorf("%s", err)
	}
	err = ValidateEmailByResolvingDomain("nomx@example.com")
	if err == nil {
		t.Errorf("invalid email address validated")
	}
}

// Normalization tests.

var sameEmails = []string{
	"test@example.com",
	"test@EXAMPLE.COM",
	"test@ExAmpLE.com",
}

var differentEmails = []string{
	"test@example.com",
	"TEST@example.com",
	"president@whitehouse.gov",
}

func TestNormalizeEmail(t *testing.T) {
	for i, v0 := range sameEmails {
		for j, v1 := range sameEmails {
			if i == j {
				continue
			}
			nv0 := NormalizeEmail(v0)
			nv1 := NormalizeEmail(v1)
			if nv0 == "" {
				t.Errorf("%d: email invalid: %q", i, v0)
			}
			if nv0 != nv1 {
				t.Errorf("%d-%d: normalized emails differ: %q and %q", i, j, nv0, nv1)
			}
		}
	}
	for i, v0 := range differentEmails {
		for j, v1 := range differentEmails {
			if i == j {
				continue
			}
			nv0 := NormalizeEmail(v0)
			nv1 := NormalizeEmail(v1)
			if nv0 == "" {
				t.Errorf("%d: email invalid: %q", i, v0)
			}
			if nv0 == nv1 {
				t.Errorf("%d-%d: normalized emails are the same: %q and %q", i, j, nv0, nv1)
			}
		}
	}
}
