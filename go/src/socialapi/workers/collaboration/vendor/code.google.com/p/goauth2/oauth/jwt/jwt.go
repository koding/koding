// Copyright 2012 The goauth2 Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// The jwt package provides support for creating credentials for OAuth2 service
// account requests.
//
// For examples of the package usage please see jwt_test.go.
// Example usage (error handling omitted for brevity):
//
//	// Craft the ClaimSet and JWT token.
//	t := &jwt.Token{
//		Key: pemKeyBytes,
//	}
//	t.ClaimSet = &jwt.ClaimSet{
//		Iss:   "XXXXXXXXXXXX@developer.gserviceaccount.com",
//		Scope: "https://www.googleapis.com/auth/devstorage.read_only",
//	}
//
//	// We need to provide a client.
//	c := &http.Client{}
//
//	// Get the access token.
//	o, _ := t.Assert(c)
//
//	// Form the request to the service.
//	req, _ := http.NewRequest("GET", "https://storage.googleapis.com/", nil)
//	req.Header.Set("Authorization", "OAuth "+o.AccessToken)
//	req.Header.Set("x-goog-api-version", "2")
//	req.Header.Set("x-goog-project-id", "XXXXXXXXXXXX")
//
//	// Make the request.
//	result, _ := c.Do(req)
//
// For info on OAuth2 service accounts please see the online documentation.
// https://developers.google.com/accounts/docs/OAuth2ServiceAccount
//
package jwt

import (
	"bytes"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"code.google.com/p/goauth2/oauth"
)

// These are the default/standard values for this to work for Google service accounts.
const (
	stdAlgorithm     = "RS256"
	stdType          = "JWT"
	stdAssertionType = "http://oauth.net/grant_type/jwt/1.0/bearer"
	stdGrantType     = "urn:ietf:params:oauth:grant-type:jwt-bearer"
	stdAud           = "https://accounts.google.com/o/oauth2/token"
)

var (
	ErrInvalidKey = errors.New("Invalid Key")
)

// base64Encode returns and Base64url encoded version of the input string with any
// trailing "=" stripped.
func base64Encode(b []byte) string {
	return strings.TrimRight(base64.URLEncoding.EncodeToString(b), "=")
}

// base64Decode decodes the Base64url encoded string
func base64Decode(s string) ([]byte, error) {
	// add back missing padding
	switch len(s) % 4 {
	case 2:
		s += "=="
	case 3:
		s += "="
	}
	return base64.URLEncoding.DecodeString(s)
}

// The JWT claim set contains information about the JWT including the
// permissions being requested (scopes), the target of the token, the issuer,
// the time the token was issued, and the lifetime of the token.
//
// Aud is usually https://accounts.google.com/o/oauth2/token
type ClaimSet struct {
	Iss   string `json:"iss"`             // email address of the client_id of the application making the access token request
	Scope string `json:"scope,omitempty"` // space-delimited list of the permissions the application requests
	Aud   string `json:"aud"`             // descriptor of the intended target of the assertion (Optional).
	Prn   string `json:"prn,omitempty"`   // email for which the application is requesting delegated access (Optional).
	Exp   int64  `json:"exp"`
	Iat   int64  `json:"iat"`
	Typ   string `json:"typ,omitempty"`

	// See http://tools.ietf.org/html/draft-jones-json-web-token-10#section-4.3
	// This array is marshalled using custom code (see (c *ClaimSet) encode()).
	PrivateClaims map[string]interface{} `json:"-"`

	exp time.Time
	iat time.Time
}

// setTimes sets iat and exp to time.Now() and iat.Add(time.Hour) respectively.
//
// Note that these times have nothing to do with the expiration time for the
// access_token returned by the server.  These have to do with the lifetime of
// the encoded JWT.
//
// A JWT can be re-used for up to one hour after it was encoded.  The access
// token that is granted will also be good for one hour so there is little point
// in trying to use the JWT a second time.
func (c *ClaimSet) setTimes(t time.Time) {
	c.iat = t
	c.exp = c.iat.Add(time.Hour)
}

var (
	jsonStart = []byte{'{'}
	jsonEnd   = []byte{'}'}
)

// encode returns the Base64url encoded form of the Signature.
func (c *ClaimSet) encode() string {
	if c.exp.IsZero() || c.iat.IsZero() {
		c.setTimes(time.Now())
	}
	if c.Aud == "" {
		c.Aud = stdAud
	}
	c.Exp = c.exp.Unix()
	c.Iat = c.iat.Unix()

	b, err := json.Marshal(c)
	if err != nil {
		panic(err)
	}

	if len(c.PrivateClaims) == 0 {
		return base64Encode(b)
	}

	// Marshal private claim set and then append it to b.
	prv, err := json.Marshal(c.PrivateClaims)
	if err != nil {
		panic(fmt.Errorf("Invalid map of private claims %v", c.PrivateClaims))
	}

	// Concatenate public and private claim JSON objects.
	if !bytes.HasSuffix(b, jsonEnd) {
		panic(fmt.Errorf("Invalid JSON %s", b))
	}
	if !bytes.HasPrefix(prv, jsonStart) {
		panic(fmt.Errorf("Invalid JSON %s", prv))
	}
	b[len(b)-1] = ','         // Replace closing curly brace with a comma.
	b = append(b, prv[1:]...) // Append private claims.

	return base64Encode(b)
}

// Header describes the algorithm and type of token being generated,
// and optionally a KeyID describing additional parameters for the
// signature.
type Header struct {
	Algorithm string `json:"alg"`
	Type      string `json:"typ"`
	KeyId     string `json:"kid,omitempty"`
}

func (h *Header) encode() string {
	b, err := json.Marshal(h)
	if err != nil {
		panic(err)
	}
	return base64Encode(b)
}

// A JWT is composed of three parts: a header, a claim set, and a signature.
// The well formed and encoded JWT can then be exchanged for an access token.
//
// The Token is not a JWT, but is is encoded to produce a well formed JWT.
//
// When obtaining a key from the Google API console it will be downloaded in a
// PKCS12 encoding.  To use this key you will need to convert it to a PEM file.
// This can be achieved with openssl.
//
//   $ openssl pkcs12 -in <key.p12> -nocerts -passin pass:notasecret -nodes -out <key.pem>
//
// The contents of this file can then be used as the Key.
type Token struct {
	ClaimSet *ClaimSet // claim set used to construct the JWT
	Header   *Header   // header used to construct the JWT
	Key      []byte    // PEM printable encoding of the private key
	pKey     *rsa.PrivateKey

	header string
	claim  string
	sig    string

	useExternalSigner bool
	signer            Signer
}

// NewToken returns a filled in *Token based on the standard header,
// and sets the Iat and Exp times based on when the call to Assert is
// made.
func NewToken(iss, scope string, key []byte) *Token {
	c := &ClaimSet{
		Iss:   iss,
		Scope: scope,
		Aud:   stdAud,
	}
	h := &Header{
		Algorithm: stdAlgorithm,
		Type:      stdType,
	}
	t := &Token{
		ClaimSet: c,
		Header:   h,
		Key:      key,
	}
	return t
}

// Signer is an interface that given a JWT token, returns the header &
// claim (serialized and urlEncoded to a byte slice), along with the
// signature and an error (if any occurred).  It could modify any data
// to sign (typically the KeyID).
//
// Example usage where a SHA256 hash of the original url-encoded token
// with an added KeyID and secret data is used as a signature:
//
//	var privateData = "secret data added to hash, indexed by KeyID"
//
//	type SigningService struct{}
//
//	func (ss *SigningService) Sign(in *jwt.Token) (newTokenData, sig []byte, err error) {
//		in.Header.KeyID = "signing service"
//		newTokenData = in.EncodeWithoutSignature()
//		dataToSign := fmt.Sprintf("%s.%s", newTokenData, privateData)
//		h := sha256.New()
//		_, err := h.Write([]byte(dataToSign))
//		sig = h.Sum(nil)
//		return
//	}
type Signer interface {
	Sign(in *Token) (tokenData, signature []byte, err error)
}

// NewSignerToken returns a *Token, using an external signer function
func NewSignerToken(iss, scope string, signer Signer) *Token {
	t := NewToken(iss, scope, nil)
	t.useExternalSigner = true
	t.signer = signer
	return t
}

// Expired returns a boolean value letting us know if the token has expired.
func (t *Token) Expired() bool {
	return t.ClaimSet.exp.Before(time.Now())
}

// Encode constructs and signs a Token returning a JWT ready to use for
// requesting an access token.
func (t *Token) encode() (string, error) {
	var tok string
	t.header = t.Header.encode()
	t.claim = t.ClaimSet.encode()
	err := t.sign()
	if err != nil {
		return tok, err
	}
	tok = fmt.Sprintf("%s.%s.%s", t.header, t.claim, t.sig)
	return tok, nil
}

// EncodeWithoutSignature returns the url-encoded value of the Token
// before signing has occurred (typically for use by external signers).
func (t *Token) EncodeWithoutSignature() string {
	t.header = t.Header.encode()
	t.claim = t.ClaimSet.encode()
	return fmt.Sprintf("%s.%s", t.header, t.claim)
}

// sign computes the signature for a Token.  The details for this can be found
// in the OAuth2 Service Account documentation.
// https://developers.google.com/accounts/docs/OAuth2ServiceAccount#computingsignature
func (t *Token) sign() error {
	if t.useExternalSigner {
		fulldata, sig, err := t.signer.Sign(t)
		if err != nil {
			return err
		}
		split := strings.Split(string(fulldata), ".")
		if len(split) != 2 {
			return errors.New("no token returned")
		}
		t.header = split[0]
		t.claim = split[1]
		t.sig = base64Encode(sig)
		return err
	}
	ss := fmt.Sprintf("%s.%s", t.header, t.claim)
	if t.pKey == nil {
		err := t.parsePrivateKey()
		if err != nil {
			return err
		}
	}
	h := sha256.New()
	h.Write([]byte(ss))
	b, err := rsa.SignPKCS1v15(rand.Reader, t.pKey, crypto.SHA256, h.Sum(nil))
	t.sig = base64Encode(b)
	return err
}

// parsePrivateKey converts the Token's Key ([]byte) into a parsed
// rsa.PrivateKey.  If the key is not well formed this method will return an
// ErrInvalidKey error.
func (t *Token) parsePrivateKey() error {
	block, _ := pem.Decode(t.Key)
	if block == nil {
		return ErrInvalidKey
	}
	parsedKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		parsedKey, err = x509.ParsePKCS1PrivateKey(block.Bytes)
		if err != nil {
			return err
		}
	}
	var ok bool
	t.pKey, ok = parsedKey.(*rsa.PrivateKey)
	if !ok {
		return ErrInvalidKey
	}
	return nil
}

// Assert obtains an *oauth.Token from the remote server by encoding and sending
// a JWT.  The access_token will expire in one hour (3600 seconds) and cannot be
// refreshed (no refresh_token is returned with the response).  Once this token
// expires call this method again to get a fresh one.
func (t *Token) Assert(c *http.Client) (*oauth.Token, error) {
	var o *oauth.Token
	u, v, err := t.buildRequest()
	if err != nil {
		return o, err
	}
	resp, err := c.PostForm(u, v)
	if err != nil {
		return o, err
	}
	o, err = handleResponse(resp)
	return o, err
}

// buildRequest sets up the URL values and the proper URL string for making our
// access_token request.
func (t *Token) buildRequest() (string, url.Values, error) {
	v := url.Values{}
	j, err := t.encode()
	if err != nil {
		return t.ClaimSet.Aud, v, err
	}
	v.Set("grant_type", stdGrantType)
	v.Set("assertion", j)
	return t.ClaimSet.Aud, v, nil
}

// Used for decoding the response body.
type respBody struct {
	IdToken   string        `json:"id_token"`
	Access    string        `json:"access_token"`
	Type      string        `json:"token_type"`
	ExpiresIn time.Duration `json:"expires_in"`
}

// handleResponse returns a filled in *oauth.Token given the *http.Response from
// a *http.Request created by buildRequest.
func handleResponse(r *http.Response) (*oauth.Token, error) {
	o := &oauth.Token{}
	defer r.Body.Close()
	if r.StatusCode != 200 {
		return o, errors.New("invalid response: " + r.Status)
	}
	b := &respBody{}
	err := json.NewDecoder(r.Body).Decode(b)
	if err != nil {
		return o, err
	}
	o.AccessToken = b.Access
	if b.IdToken != "" {
		// decode returned id token to get expiry
		o.AccessToken = b.IdToken
		s := strings.Split(b.IdToken, ".")
		if len(s) < 2 {
			return nil, errors.New("invalid token received")
		}
		d, err := base64Decode(s[1])
		if err != nil {
			return o, err
		}
		c := &ClaimSet{}
		err = json.NewDecoder(bytes.NewBuffer(d)).Decode(c)
		if err != nil {
			return o, err
		}
		o.Expiry = time.Unix(c.Exp, 0)
		return o, nil
	}
	o.Expiry = time.Now().Add(b.ExpiresIn * time.Second)
	return o, nil
}
