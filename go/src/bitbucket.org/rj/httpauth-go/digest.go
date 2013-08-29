// Copyright 2012 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package httpauth

import (
	"container/heap"
	"crypto/md5"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"hash"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	// The default value for ClientCacheResidence used when creating new Digest instances.
	DefaultClientCacheResidence = 1 * time.Hour
	// The length of a nonce
	nonceLen = 16
)

type digestClientInfo struct {
	numContacts uint64 // number of client connects
	lastContact int64  // time of last communication with this client (unix nanoseconds)
	nonce       string // unique per client salt
}

type digestPriorityQueue []*digestClientInfo

func (pq digestPriorityQueue) Len() int {
	return len(pq)
}

func (pq digestPriorityQueue) Less(i, j int) bool {
	return pq[i].lastContact < pq[j].lastContact
}

func (pq digestPriorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
}

func (pq *digestPriorityQueue) Push(x interface{}) {
	*pq = append(*pq, x.(*digestClientInfo))
}

func (pq *digestPriorityQueue) Pop() interface{} {
	n := len(*pq)
	ret := (*pq)[n-1]
	*pq = (*pq)[:n-1]
	return ret
}

func (pq digestPriorityQueue) MinValue() int64 {
	n := len(pq)
	return pq[n-1].lastContact
}

// A Digest is a policy for authenticating users using the digest authentication scheme.
type Digest struct {
	// Realm provides a 'namespace' where the authentication will be considered.
	Realm string
	// Auth provides a function or closure that retrieve the password for a given username.
	Auth PasswordLookup
	// WriteUnauthorized provides a function or closure that writes out the HTML portion of a unauthorized access response.
	WriteUnauthorized HtmlWriter
	// This is a nonce used by the HTTP server to prevent dictionary attacks
	opaque string

	// CientCacheResidence controls how long client information is retained
	ClientCacheResidence time.Duration

	mutex   sync.Mutex
	clients map[string]*digestClientInfo
	lru     digestPriorityQueue
	md5     hash.Hash
}

func createNonce() (string, error) {
	var buffer [12]byte

	for i := 0; i < len(buffer); {
		n, err := rand.Read(buffer[i:])
		if err != nil {
			return "", err
		}
		i += n
	}
	return base64.StdEncoding.EncodeToString(buffer[0:]), nil
}

func calcHash(h hash.Hash, data string) string {
	h.Reset()
	h.Write([]byte(data))
	return fmt.Sprintf("%x", h.Sum(nil))
}

// NewDigest creates a new authentication policy that uses the digest authentication scheme.
func NewDigest(realm string, auth PasswordLookup, writer HtmlWriter) (*Digest, error) {
	nonce, err := createNonce()
	if err != nil {
		return nil, err
	}

	if writer == nil {
		writer = defaultHtmlWriter
	}

	return &Digest{
		realm,
		auth,
		writer,
		nonce,
		DefaultClientCacheResidence,
		sync.Mutex{},
		make(map[string]*digestClientInfo),
		nil,
		md5.New()}, nil
}

func (a *Digest) evictLeastRecentlySeen() {
	now := time.Now().UnixNano()

	// Remove all entries from the client cache older than the
	// residence time.
	for len(a.lru) > 0 && a.lru.MinValue()+a.ClientCacheResidence.Nanoseconds() <= now {
		client := heap.Pop(&a.lru).(*digestClientInfo)
		delete(a.clients, client.nonce)
	}
}

func parseDigestAuthHeader(r *http.Request) map[string]string {
	// Extract the authentication token.
	token := r.Header.Get("Authorization")
	if token == "" {
		return nil
	}

	// Check that the token supplied corresponds to the digest authorization
	// protocol.  If not, return nil to indicate failure.  No error
	// code is used as a malformed protocol is simply an authentication
	// failure.
	ndx := strings.IndexRune(token, ' ')
	if ndx < 1 || token[0:ndx] != "Digest" {
		return nil
	}
	token = token[ndx+1:]

	// Token is a comma separated list of name/value pairs.  Break-out pieces
	// and fill in a map.
	params := make(map[string]string)
	for _, str := range strings.Split(token, ",") {
		ndx := strings.IndexRune(str, '=')
		if ndx < 1 {
			// malformed name/value pair
			// ignore
			continue
		}
		name := strings.Trim(str[0:ndx], `" `)
		value := strings.Trim(str[ndx+1:], `" `)
		params[name] = value
	}

	return params
}

// Authorize retrieves the credientials from the HTTP request, and
// returns the username only if the credientials could be validated.
// If the return value is blank, then the credentials are missing,
// invalid, or a system error prevented verification.
func (a *Digest) Authorize(r *http.Request) (username string) {
	// Extract and parse the token
	params := parseDigestAuthHeader(r)
	if params == nil {
		return ""
	}

	// Verify the token's parameters
	if params["opaque"] != a.opaque || params["algorithm"] != "MD5" || params["qop"] != "auth" {
		return ""
	}

	// Verify if the requested URI matches auth header
	switch u, err := url.Parse(params["uri"]); {
	case err != nil || r.URL == nil:
		return
	case r.URL.Path != u.Path:
		return
	}

	username = params["username"]
	if username == "" {
		return ""
	}
	password := a.Auth(username)
	if password == "" {
		return ""
	}
	ha1 := calcHash(a.md5, username+":"+a.Realm+":"+password)
	ha2 := calcHash(a.md5, r.Method+":"+params["uri"])
	ha3 := calcHash(a.md5, ha1+":"+params["nonce"]+":"+params["nc"]+
		":"+params["cnonce"]+":"+params["qop"]+":"+ha2)
	if ha3 != params["response"] {
		return ""
	}

	// Determine the number of contacts that the client believes that
	// it has had with this serveri.
	numContacts, err := strconv.ParseUint(params["nc"], 16, 64)
	if err != nil {
		return ""
	}

	// Pull out the nonce, and verify
	nonce, ok := params["nonce"]
	if !ok || len(nonce) != nonceLen {
		return ""
	}

	// The next block of actions require accessing field internal to the
	// digest structure.  Need to lock.
	a.mutex.Lock()
	defer a.mutex.Unlock()

	// Check for old clientInfo, and evict those older than
	// residence time.
	a.evictLeastRecentlySeen()

	// Find the client, and check against authorization parameters.
	if client, ok := a.clients[nonce]; ok {
		if client.numContacts != 0 && client.numContacts >= numContacts {
			return ""
		}
		client.numContacts = numContacts
		client.lastContact = time.Now().UnixNano()
	} else {
		return ""
	}

	return username
}

// NotifyAuthRequired adds the headers to the HTTP response to
// inform the client of the failed authorization, and which scheme
// must be used to gain authentication.
func (a *Digest) NotifyAuthRequired(w http.ResponseWriter, r *http.Request) {
	// Create an entry for the client
	nonce, err := createNonce()
	if err != nil {
		http.Error(w, "Internal server error.", http.StatusInternalServerError)
		return
	}

	// Create the header
	hdr := `Digest realm="` + a.Realm + `", nonce="` + nonce + `", opaque="` +
		a.opaque + `", algorithm="MD5", qop="auth"`
	w.Header().Set("WWW-Authenticate", hdr)
	w.WriteHeader(http.StatusUnauthorized)
	a.WriteUnauthorized(w, r)

	// The next block of actions require accessing field internal to the
	// digest structure.  Need to lock.
	a.mutex.Lock()
	defer a.mutex.Unlock()

	// Add the client info to the LRU.
	ci := &digestClientInfo{0, time.Now().UnixNano(), nonce}
	a.clients[nonce] = ci
	heap.Push(&a.lru, ci)
}

// Logout removes the nonce associated with the HTTP request from the cache.
func (a *Digest) Logout(r *http.Request) {
	// Extract the authentication parameters
	params := parseDigestAuthHeader(r)
	if params == nil {
		return
	}

	nonce, ok := params["nonce"]
	if !ok {
		return
	}

	// The next block of actions require accessing field internal to the
	// digest structure.  Need to lock.
	a.mutex.Lock()
	defer a.mutex.Unlock()

	// Use the nonce to find the entry
	if client, ok := a.clients[nonce]; ok {
		// Increase the time since last contact, and force an eviction.
		client.lastContact = 0
	}
}
