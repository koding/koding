// Copyright 2012 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package httpauth

import (
	"container/heap"
	"errors"
	"html"
	"net/http"
	"time"
)

var (
	ErrBadUsernameOrPassword = errors.New("Bad username or password.")
	ErrInvalidToken          = errors.New("The session token was invalid.")
)

type cookieClientInfo struct {
	username    string // username for this authorized connection
	lastContact int64  // time of last communication with this client (unix nanoseconds)
	nonce       string // unique per client salt
}

type cookiePriorityQueue []*cookieClientInfo

func (pq cookiePriorityQueue) Len() int {
	return len(pq)
}

func (pq cookiePriorityQueue) Less(i, j int) bool {
	return pq[i].lastContact < pq[j].lastContact
}

func (pq cookiePriorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
}

func (pq *cookiePriorityQueue) Push(x interface{}) {
	*pq = append(*pq, x.(*cookieClientInfo))
}

func (pq *cookiePriorityQueue) Pop() interface{} {
	n := len(*pq)
	ret := (*pq)[n-1]
	*pq = (*pq)[:n-1]
	return ret
}

func (pq cookiePriorityQueue) MinValue() int64 {
	n := len(pq)
	return pq[n-1].lastContact
}

// A Cookie is a policy for authenticating users that uses a cookie stored
// on the client to verify authorized clients.  This authentication scheme
// is more involved than the others, as callers will need to implement URLs
// for login and logout pages.
type Cookie struct {
	// Realm provides a 'namespace' where the authentication will be considered.
	Realm string
	// Auth provides a function or closure that can validate if a username/password combination is valid
	Auth Authenticator
	// Clients are redirected to the LoginPage when they don't have authorization
	LoginPage string

	// CientCacheResidence controls how long client information is retained
	ClientCacheResidence time.Duration

	clientsByNonce map[string]*cookieClientInfo
	clientsByUser  map[string]*cookieClientInfo
	lru            cookiePriorityQueue
}

// NewCookie creates a new authentication policy that uses the cookie authentication scheme.
func NewCookie(realm, url string, auth Authenticator) *Cookie {
	return &Cookie{
		realm,
		auth,
		url,
		DefaultClientCacheResidence,
		make(map[string]*cookieClientInfo),
		make(map[string]*cookieClientInfo),
		nil}
}

func (a *Cookie) evictLeastRecentlySeen() {
	now := time.Now().UnixNano()

	// Remove all entries from the client cache older than the
	// residence time.
	for len(a.lru) > 0 && a.lru.MinValue()+a.ClientCacheResidence.Nanoseconds() <= now {
		client := heap.Pop(&a.lru).(*cookieClientInfo)
		delete(a.clientsByNonce, client.nonce)
		delete(a.clientsByUser, client.username)
	}
}

// Authorize retrieves the credientials from the HTTP request, and
// returns the username only if the credientials could be validated.
// If the return value is blank, then the credentials are missing,
// invalid, or a system error prevented verification.
func (a *Cookie) Authorize(r *http.Request) (username string) {
	// Find the nonce used to identify a client
	token, err := r.Cookie("Authorization")
	if err != nil || token.Value == "" {
		return ""
	}

	// Do we have a client with that nonce?
	if client, ok := a.clientsByNonce[token.Value]; ok {
		client.lastContact = time.Now().UnixNano()
		return client.username
	}
	return ""
}

// NotifyAuthRequired adds the headers to the HTTP response to
// inform the client of the failed authorization, and which scheme
// must be used to gain authentication.
//
// Caller's should consider adding sending an HTML response with a link
// to the login page for GET requests.
func (a *Cookie) NotifyAuthRequired(w http.ResponseWriter, r *http.Request) {
	// Check for old clientInfo, and evict those older than
	// residence time.
	a.evictLeastRecentlySeen()

	// This code is derived from http.Redirect
	w.Header().Set("Location", a.LoginPage)
	w.WriteHeader(http.StatusTemporaryRedirect)

	// RFC2616 recommends that a short note "SHOULD" be included in the
	// response because older user agents may not understand 301/307.
	// Shouldn't send the response for POST or HEAD; that leaves GET.
	if r.Method == "GET" {
		note := "<a href=\"" + html.EscapeString(a.LoginPage) + "\">" + http.StatusText(http.StatusTemporaryRedirect) + "</a>.\n"
		w.Write([]byte(note))
	}
}

// Login checks the credentials of a client, and, if valid, creates a client
// entry.  The nonce can be used by the client to identify the session.
// Most callers will most likely be interested in LoginWithResponse.
//
// If the credentials cannot be verified, an error will be returned (ErrBadUsernameOrPassword).
func (a *Cookie) Login(username, password string) (nonce string, err error) {
	// Authorize the user
	if !a.Auth(username, password) {
		return "", ErrBadUsernameOrPassword
	}

	// Check if there is already a session for this username
	if ci, ok := a.clientsByUser[username]; ok {
		ci.lastContact = time.Now().UnixNano()
		return ci.nonce, nil
	}

	// Create an entry for this user
	nonce, err = createNonce()
	if err != nil {
		return "", err
	}
	ci := &cookieClientInfo{username, time.Now().UnixNano(), nonce}
	a.clientsByNonce[nonce] = ci
	a.clientsByUser[username] = ci

	return nonce, nil
}

// LoginWithResponse checks the credentials of the client.  If successful, a
// cookie is on the response so that the client can access the session again.
//
// The caller is responsable for create an appropriate response to the HTTP request.
// For successful validation, redirection (http.StatusTemporaryRedirect) to the
// protected content is most likely the correct response.
//
// If the credentials cannot be verified, an error (ErrBadUsernameOrPassword) is
// returned.  The caller is then responsable for creating an appropriate reponse to
// the HTTP request.
func (a *Cookie) LoginWithResponse(w http.ResponseWriter, username, password string) error {
	nonce, err := a.Login(username, password)
	if err != nil {
		return err
	}

	http.SetCookie(w, &http.Cookie{Name: "Authorization", Value: nonce})
	return nil
}

// Logout ensures that the nonce is no longer valid.
func (a *Cookie) Logout(nonce string) {
	// Do we have a client with that nonce?
	if client, ok := a.clientsByNonce[nonce]; ok {
		// remove client info from maps
		delete(a.clientsByNonce, nonce)
		delete(a.clientsByUser, client.username)
		// client info is still in the priority queue
		// however, it will be removed in due time when it expires
	}
}

// LogoutWithResponse ensures that the session associated with the HTTP request
// is no longer valid.  It sets a header on the response to erase any cookies
// used by the client to identify the session.
func (a *Cookie) LogoutWithReponse(w http.ResponseWriter, r *http.Request) error {
	// Find the nonce used to identify a client
	token, err := r.Cookie("Authorization")
	if err == nil || token.Value != "" {
		// Invalidate the nonce
		a.Logout(token.Value)
	}

	// Clear the cookie from the client
	http.SetCookie(w, &http.Cookie{Name: "Authorization", Value: "", Expires: time.Unix(0, 0)})
	return nil
}
