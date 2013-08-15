// Copyright 2013 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package httpauth

import (
	"net/http"
)

type authHandler struct {
	auth    Policy
	handler http.Handler
}

func (a *authHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	username := a.auth.Authorize(r)
	if username == "" {
		a.auth.NotifyAuthRequired(w, r)
		return
	}

	a.handler.ServeHTTP(w, r)
}

// NewHandler returns a http.Handler that checks the HTTP request's
// credentials for authentication.  If successful, control will then
// pass to handler.
//
// Note, if the handler requires access to the username from the credentials,
// then this function is not useable.  Instead, you will need to work with
// the authorization policy directly.  See examples.
func NewHandlerWithAuth(auth Policy, handler http.Handler) http.Handler {
	return &authHandler{auth, handler}
}
