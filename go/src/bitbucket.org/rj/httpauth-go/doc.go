// Copyright 2012 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package httpauth provides utilities to support HTTP authentication policies.
//
// The HTTP standard provides two different schemes for authorizing clients: the
// basic authorization scheme and the digest authorization scheme.  Both schemes
// are supported by the package, and the supporting types implement a common policy
// interface so that HTTP servers can easily change their authentication policy.
//
// To support the basic authentication scheme, callers will need to provide a 
// function or closure that can validate a user's credentials (i.e. a username 
// and password pair).  Alternatively, callers can provide a function that will 
// retrieve the password for a given username.
//
// To support the diget authentication scheme, callers will need to provide a
// function or cluse that can retrieve the password for a given username.  The
// alternate approach (validating a set of credentials) is not supported.
package httpauth
