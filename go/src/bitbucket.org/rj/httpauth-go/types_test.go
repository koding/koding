// Copyright 2012 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package httpauth

import (
	"testing"
)

func TestPasswordLookup_Authenticator(t *testing.T) {
	p := PasswordLookup(func(username string) string {
		return username + "_"
	})

	a := p.Authenticator()

	if a("a", "a") {
		t.Errorf("False positive")
	}
	if !a("a", "a_") {
		t.Errorf("False negative")
	}
}
