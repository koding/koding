// Copyright 2012 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package httpauth

import (
	"io"
	"net/http"
)

// An Authenticator is a caller supplied closure that can check the authorization
// of user's credentials (i.e. a username and password pair).  The function should
// return true only if the credentials can be successfully validated.
type Authenticator func(username, password string) bool

// A PasswordLookup is a caller supplied closure that can find the password
// for a supplied username.  The function should return a empty string if
// the user's password could not be determined.
type PasswordLookup func(username string) string

// Authenticator converts the password lookup function into a closure
// that validates a username/password pair.
func (p PasswordLookup) Authenticator() Authenticator {
	return func(username, password string) bool {
		pwd := p(username)
		return pwd != "" && password == pwd
	}
}

// An HtmlWriter is a function or closure that will write HTML
// for a response.  A http.ResponseWriter is not used, as normal
// for other HTTP responses, because the headers are already
// provided by the authentication policy.
type HtmlWriter func(w io.Writer, ret *http.Request)

// A Policy is a type that implements a HTTP authentication scheme.  Two
// standard schemes are the basic authentication scheme and the digest
// access authentication scheme.
type Policy interface {
	// Authorize retrieves the credientials from the HTTP request, and
	// returns the username only if the credientials could be validated.
	// If the return value is blank, then the credentials are missing,
	// invalid, or a system error prevented verification.
	//
	// This function can be used to build a handler.  Most users should
	// probably simply wrap their handler using NewAuthHandler.
	Authorize(r *http.Request) (username string)
	// NotifyAuthRequired adds the headers to the HTTP response to
	// inform the client of the failed authorization, and which scheme
	// must be used to gain authentication.
	//
	// This function can be used to build a handler.  Most users should
	// probably simply wrap their handler using NewAuthHandler.
	NotifyAuthRequired(w http.ResponseWriter, r *http.Request)
}
