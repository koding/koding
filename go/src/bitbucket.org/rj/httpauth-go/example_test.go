// Copyright 2012 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package httpauth

import (
	"fmt"
	"net/http"
	"time"
)

func ExampleNewBasic() {
	// Create an authorization policy that uses the basic authorization
	// scheme.  The credientials will be considered valid if the password
	// is simply the username repeated twice.
	auth := NewBasic("My Website", func(username, password string) bool {
		return password == username+username
	}, nil)
	// The request handler
	http.HandleFunc("/example/", func(w http.ResponseWriter, r *http.Request) {
		// Check if the client is authorized
		username := auth.Authorize(r)
		if username == "" {
			// Oops!  Access denied.
			auth.NotifyAuthRequired(w,r)
			return
		}
		fmt.Fprintf(w, "<html><body><h1>Hello</h1><p>Welcome, %s</p></body></html>", username)
	})

	// This is just an example.  Run the HTTP server for a second and then quit.
	go http.ListenAndServe(port, nil)
	time.Sleep(1 * time.Second)
}

func ExamplePasswordLookup_Authenticator() {
	// Create a dummy PasswordLookup for this example.
	pl := PasswordLookup(func(username string) string {
		// A user's password is their username with the digit '9' added
		return username + "9"
	})

	// To use the basic authentication scheme, we need an Authenicator
	auth := pl.Authenticator()

	// Create a authentication scheme
	_ /*policy*/ = NewBasic("My Website", auth, nil)
}
