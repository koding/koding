// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package acme provides an implementation of the
// Automatic Certificate Management Environment (ACME) spec.
// See https://tools.ietf.org/html/draft-ietf-acme-acme-02 for details.
//
// This package is a work in progress and makes no API stability promises.
package acme

import (
	"bytes"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"math/big"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/net/context"
	"golang.org/x/net/context/ctxhttp"
)

// LetsEncryptURL is the Directory endpoint of Let's Encrypt CA.
const LetsEncryptURL = "https://acme-v01.api.letsencrypt.org/directory"

const (
	maxChainLen = 5       // max depth and breadth of a certificate chain
	maxCertSize = 1 << 20 // max size of a certificate, in bytes
)

// Client is an ACME client.
// The only required field is Key. An example of creating a client with a new key
// is as follows:
//
// 	key, err := rsa.GenerateKey(rand.Reader, 2048)
// 	if err != nil {
// 		log.Fatal(err)
// 	}
// 	client := &Client{Key: key}
//
type Client struct {
	// Key is the account key used to register with a CA and sign requests.
	// Key.Public() must return a *rsa.PublicKey or *ecdsa.PublicKey.
	Key crypto.Signer

	// HTTPClient optionally specifies an HTTP client to use
	// instead of http.DefaultClient.
	HTTPClient *http.Client

	// DirectoryURL points to the CA directory endpoint.
	// If empty, LetsEncryptURL is used.
	// Mutating this value after a successful call of Client's Discover method
	// will have no effect.
	DirectoryURL string

	dirMu sync.Mutex // guards writes to dir
	dir   *Directory // cached result of Client's Discover method
}

// Discover performs ACME server discovery using c.DirectoryURL.
//
// It caches successful result. So, subsequent calls will not result in
// a network round-trip. This also means mutating c.DirectoryURL after successful call
// of this method will have no effect.
func (c *Client) Discover(ctx context.Context) (Directory, error) {
	c.dirMu.Lock()
	defer c.dirMu.Unlock()
	if c.dir != nil {
		return *c.dir, nil
	}

	dirURL := c.DirectoryURL
	if dirURL == "" {
		dirURL = LetsEncryptURL
	}
	res, err := ctxhttp.Get(ctx, c.HTTPClient, dirURL)
	if err != nil {
		return Directory{}, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return Directory{}, responseError(res)
	}

	var v struct {
		Reg    string `json:"new-reg"`
		Authz  string `json:"new-authz"`
		Cert   string `json:"new-cert"`
		Revoke string `json:"revoke-cert"`
		Meta   struct {
			Terms   string   `json:"terms-of-service"`
			Website string   `json:"website"`
			CAA     []string `json:"caa-identities"`
		}
	}
	if json.NewDecoder(res.Body).Decode(&v); err != nil {
		return Directory{}, err
	}
	c.dir = &Directory{
		RegURL:    v.Reg,
		AuthzURL:  v.Authz,
		CertURL:   v.Cert,
		RevokeURL: v.Revoke,
		Terms:     v.Meta.Terms,
		Website:   v.Meta.Website,
		CAA:       v.Meta.CAA,
	}
	return *c.dir, nil
}

// CreateCert requests a new certificate using the Certificate Signing Request csr encoded in DER format.
// The exp argument indicates the desired certificate validity duration. CA may issue a certificate
// with a different duration.
// If the bundle argument is true, the returned value will also contain the CA (issuer) certificate chain.
//
// In the case where CA server does not provide the issued certificate in the response,
// CreateCert will poll certURL using c.FetchCert, which will result in additional round-trips.
// In such scenario the caller can cancel the polling with ctx.
//
// CreateCert returns an error if the CA's response or chain was unreasonably large.
// Callers are encouraged to parse the returned value to ensure the certificate is valid and has the expected features.
func (c *Client) CreateCert(ctx context.Context, csr []byte, exp time.Duration, bundle bool) (der [][]byte, certURL string, err error) {
	if _, err := c.Discover(ctx); err != nil {
		return nil, "", err
	}

	req := struct {
		Resource  string `json:"resource"`
		CSR       string `json:"csr"`
		NotBefore string `json:"notBefore,omitempty"`
		NotAfter  string `json:"notAfter,omitempty"`
	}{
		Resource: "new-cert",
		CSR:      base64.RawURLEncoding.EncodeToString(csr),
	}
	now := timeNow()
	req.NotBefore = now.Format(time.RFC3339)
	if exp > 0 {
		req.NotAfter = now.Add(exp).Format(time.RFC3339)
	}

	res, err := postJWS(ctx, c.HTTPClient, c.Key, c.dir.CertURL, req)
	if err != nil {
		return nil, "", err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusCreated {
		return nil, "", responseError(res)
	}

	curl := res.Header.Get("location") // cert permanent URL
	if res.ContentLength == 0 {
		// no cert in the body; poll until we get it
		cert, err := c.FetchCert(ctx, curl, bundle)
		return cert, curl, err
	}
	// slurp issued cert and CA chain, if requested
	cert, err := responseCert(ctx, c.HTTPClient, res, bundle)
	return cert, curl, err
}

// FetchCert retrieves already issued certificate from the given url, in DER format.
// It retries the request until the certificate is successfully retrieved,
// context is cancelled by the caller or an error response is received.
//
// The returned value will also contain the CA (issuer) certificate if the bundle argument is true.
//
// FetchCert returns an error if the CA's response or chain was unreasonably large.
// Callers are encouraged to parse the returned value to ensure the certificate is valid
// and has expected features.
func (c *Client) FetchCert(ctx context.Context, url string, bundle bool) ([][]byte, error) {
	for {
		res, err := ctxhttp.Get(ctx, c.HTTPClient, url)
		if err != nil {
			return nil, err
		}
		defer res.Body.Close()
		if res.StatusCode == http.StatusOK {
			return responseCert(ctx, c.HTTPClient, res, bundle)
		}
		if res.StatusCode > 299 {
			return nil, responseError(res)
		}
		d, err := retryAfter(res.Header.Get("retry-after"))
		if err != nil {
			d = 3 * time.Second
		}
		select {
		case <-time.After(d):
			// retry
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}
}

// AcceptTOS always returns true to indicate the acceptance of a CA's Terms of Service
// during account registration. See Register method of Client for more details.
func AcceptTOS(tosURL string) bool { return true }

// Register creates a new account registration by following the "new-reg" flow.
// It returns registered account. The a argument is not modified.
//
// The registration may require the caller to agree to the CA's Terms of Service (TOS).
// If so, and the account has not indicated the acceptance of the terms (see Account for details),
// Register calls prompt with a TOS URL provided by the CA. Prompt should report
// whether the caller agrees to the terms. To always accept the terms, the caller can use AcceptTOS.
func (c *Client) Register(ctx context.Context, a *Account, prompt func(tosURL string) bool) (*Account, error) {
	if _, err := c.Discover(ctx); err != nil {
		return nil, err
	}

	var err error
	if a, err = c.doReg(ctx, c.dir.RegURL, "new-reg", a); err != nil {
		return nil, err
	}
	var accept bool
	if a.CurrentTerms != "" && a.CurrentTerms != a.AgreedTerms {
		accept = prompt(a.CurrentTerms)
	}
	if accept {
		a.AgreedTerms = a.CurrentTerms
		a, err = c.UpdateReg(ctx, a)
	}
	return a, err
}

// GetReg retrieves an existing registration.
// The url argument is an Account URI.
func (c *Client) GetReg(ctx context.Context, url string) (*Account, error) {
	a, err := c.doReg(ctx, url, "reg", nil)
	if err != nil {
		return nil, err
	}
	a.URI = url
	return a, nil
}

// UpdateReg updates an existing registration.
// It returns an updated account copy. The provided account is not modified.
func (c *Client) UpdateReg(ctx context.Context, a *Account) (*Account, error) {
	uri := a.URI
	a, err := c.doReg(ctx, uri, "reg", a)
	if err != nil {
		return nil, err
	}
	a.URI = uri
	return a, nil
}

// Authorize performs the initial step in an authorization flow.
// The caller will then need to choose from and perform a set of returned
// challenges using c.Accept in order to successfully complete authorization.
func (c *Client) Authorize(ctx context.Context, domain string) (*Authorization, error) {
	if _, err := c.Discover(ctx); err != nil {
		return nil, err
	}

	type authzID struct {
		Type  string `json:"type"`
		Value string `json:"value"`
	}
	req := struct {
		Resource   string  `json:"resource"`
		Identifier authzID `json:"identifier"`
	}{
		Resource:   "new-authz",
		Identifier: authzID{Type: "dns", Value: domain},
	}
	res, err := postJWS(ctx, c.HTTPClient, c.Key, c.dir.AuthzURL, req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusCreated {
		return nil, responseError(res)
	}

	var v wireAuthz
	if err := json.NewDecoder(res.Body).Decode(&v); err != nil {
		return nil, fmt.Errorf("acme: invalid response: %v", err)
	}
	if v.Status != StatusPending {
		return nil, fmt.Errorf("acme: unexpected status: %s", v.Status)
	}
	return v.authorization(res.Header.Get("Location")), nil
}

// GetAuthz retrieves the current status of an authorization flow.
//
// A client typically polls an authz status using this method.
func (c *Client) GetAuthz(ctx context.Context, url string) (*Authorization, error) {
	res, err := ctxhttp.Get(ctx, c.HTTPClient, url)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK && res.StatusCode != http.StatusAccepted {
		return nil, responseError(res)
	}
	var v wireAuthz
	if err := json.NewDecoder(res.Body).Decode(&v); err != nil {
		return nil, fmt.Errorf("acme: invalid response: %v", err)
	}
	return v.authorization(url), nil
}

// GetChallenge retrieves the current status of an challenge.
//
// A client typically polls a challenge status using this method.
func (c *Client) GetChallenge(ctx context.Context, url string) (*Challenge, error) {
	res, err := ctxhttp.Get(ctx, c.HTTPClient, url)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK && res.StatusCode != http.StatusAccepted {
		return nil, responseError(res)
	}
	v := wireChallenge{URI: url}
	if err := json.NewDecoder(res.Body).Decode(&v); err != nil {
		return nil, fmt.Errorf("acme: invalid response: %v", err)
	}
	return v.challenge(), nil
}

// Accept informs the server that the client accepts one of its challenges
// previously obtained with c.Authorize.
//
// The server will then perform the validation asynchronously.
func (c *Client) Accept(ctx context.Context, chal *Challenge) (*Challenge, error) {
	auth, err := keyAuth(c.Key.Public(), chal.Token)
	if err != nil {
		return nil, err
	}

	req := struct {
		Resource string `json:"resource"`
		Type     string `json:"type"`
		Auth     string `json:"keyAuthorization"`
	}{
		Resource: "challenge",
		Type:     chal.Type,
		Auth:     auth,
	}
	res, err := postJWS(ctx, c.HTTPClient, c.Key, chal.URI, req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	// Note: the protocol specifies 200 as the expected response code, but
	// letsencrypt seems to be returning 202.
	if res.StatusCode != http.StatusOK && res.StatusCode != http.StatusAccepted {
		return nil, responseError(res)
	}

	var v wireChallenge
	if err := json.NewDecoder(res.Body).Decode(&v); err != nil {
		return nil, fmt.Errorf("acme: invalid response: %v", err)
	}
	return v.challenge(), nil
}

// HTTP01ChallengeResponse returns the response for an http-01 challenge.
// Servers should respond with the value to HTTP requests at the URL path
// provided by HTTP01ChallengePath to validate the challenge and prove control
// over a domain name.
//
// The token argument is a Challenge.Token value.
func (c *Client) HTTP01ChallengeResponse(token string) (string, error) {
	return keyAuth(c.Key.Public(), token)
}

// HTTP01ChallengePath returns the URL path at which the response for an http-01 challenge
// should be provided by the servers.
// The response value can be obtained with HTTP01ChallengeResponse.
//
// The token argument is a Challenge.Token value.
func (c *Client) HTTP01ChallengePath(token string) string {
	return "/.well-known/acme-challenge/" + token
}

// TLSSNI01ChallengeCert creates a certificate for TLS-SNI-01 challenge response.
// Servers can present the certificate to validate the challenge and prove control
// over a domain name.
//
// The implementation is incomplete in that the returned value is a single certificate,
// computed only for Z0 of the key authorization. ACME CAs are expected to update
// their implementations to use the newer version, TLS-SNI-02.
// For more details on TLS-SNI-01 see https://tools.ietf.org/html/draft-ietf-acme-acme-01#section-7.3.
//
// The token argument is a Challenge.Token value.
//
// The returned certificate is valid for the next 24 hours and must be presented only when
// the server name of the client hello matches exactly the returned name value.
func (c *Client) TLSSNI01ChallengeCert(token string) (cert tls.Certificate, name string, err error) {
	ka, err := keyAuth(c.Key.Public(), token)
	if err != nil {
		return tls.Certificate{}, "", err
	}
	b := sha256.Sum256([]byte(ka))
	h := hex.EncodeToString(b[:])
	name = fmt.Sprintf("%s.%s.acme.invalid", h[:32], h[32:])
	cert, err = tlsChallengeCert(name)
	if err != nil {
		return tls.Certificate{}, "", err
	}
	return cert, name, nil
}

// TLSSNI02ChallengeCert creates a certificate for TLS-SNI-02 challenge response.
// Servers can present the certificate to validate the challenge and prove control
// over a domain name. For more details on TLS-SNI-02 see
// https://tools.ietf.org/html/draft-ietf-acme-acme-03#section-7.3.
//
// The token argument is a Challenge.Token value.
//
// The returned certificate is valid for the next 24 hours and must be presented only when
// the server name in the client hello matches exactly the returned name value.
func (c *Client) TLSSNI02ChallengeCert(token string) (cert tls.Certificate, name string, err error) {
	b := sha256.Sum256([]byte(token))
	h := hex.EncodeToString(b[:])
	sanA := fmt.Sprintf("%s.%s.token.acme.invalid", h[:32], h[32:])

	ka, err := keyAuth(c.Key.Public(), token)
	if err != nil {
		return tls.Certificate{}, "", err
	}
	b = sha256.Sum256([]byte(ka))
	h = hex.EncodeToString(b[:])
	sanB := fmt.Sprintf("%s.%s.ka.acme.invalid", h[:32], h[32:])

	cert, err = tlsChallengeCert(sanA, sanB)
	if err != nil {
		return tls.Certificate{}, "", err
	}
	return cert, sanA, nil
}

// doReg sends all types of registration requests.
// The type of request is identified by typ argument, which is a "resource"
// in the ACME spec terms.
//
// A non-nil acct argument indicates whether the intention is to mutate data
// of the Account. Only Contact and Agreement of its fields are used
// in such cases.
func (c *Client) doReg(ctx context.Context, url string, typ string, acct *Account) (*Account, error) {
	req := struct {
		Resource  string   `json:"resource"`
		Contact   []string `json:"contact,omitempty"`
		Agreement string   `json:"agreement,omitempty"`
	}{
		Resource: typ,
	}
	if acct != nil {
		req.Contact = acct.Contact
		req.Agreement = acct.AgreedTerms
	}
	res, err := postJWS(ctx, c.HTTPClient, c.Key, url, req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode < 200 || res.StatusCode > 299 {
		return nil, responseError(res)
	}

	var v struct {
		Contact        []string
		Agreement      string
		Authorizations string
		Certificates   string
	}
	if err := json.NewDecoder(res.Body).Decode(&v); err != nil {
		return nil, fmt.Errorf("acme: invalid response: %v", err)
	}
	var tos string
	if v := linkHeader(res.Header, "terms-of-service"); len(v) > 0 {
		tos = v[0]
	}
	var authz string
	if v := linkHeader(res.Header, "next"); len(v) > 0 {
		authz = v[0]
	}
	return &Account{
		URI:            res.Header.Get("Location"),
		Contact:        v.Contact,
		AgreedTerms:    v.Agreement,
		CurrentTerms:   tos,
		Authz:          authz,
		Authorizations: v.Authorizations,
		Certificates:   v.Certificates,
	}, nil
}

func responseCert(ctx context.Context, client *http.Client, res *http.Response, bundle bool) ([][]byte, error) {
	b, err := ioutil.ReadAll(io.LimitReader(res.Body, maxCertSize+1))
	if err != nil {
		return nil, fmt.Errorf("acme: response stream: %v", err)
	}
	if len(b) > maxCertSize {
		return nil, errors.New("acme: certificate is too big")
	}
	cert := [][]byte{b}
	if !bundle {
		return cert, nil
	}

	// Append CA chain cert(s).
	// At least one is required according to the spec:
	// https://tools.ietf.org/html/draft-ietf-acme-acme-03#section-6.3.1
	up := linkHeader(res.Header, "up")
	if len(up) == 0 {
		return nil, errors.New("acme: rel=up link not found")
	}
	if len(up) > maxChainLen {
		return nil, errors.New("acme: rel=up link is too large")
	}
	for _, url := range up {
		cc, err := chainCert(ctx, client, url, 0)
		if err != nil {
			return nil, err
		}
		cert = append(cert, cc...)
	}
	return cert, nil
}

// responseError creates an error of Error type from resp.
func responseError(resp *http.Response) error {
	// don't care if ReadAll returns an error:
	// json.Unmarshal will fail in that case anyway
	b, _ := ioutil.ReadAll(resp.Body)
	e := struct {
		Status int
		Type   string
		Detail string
	}{
		Status: resp.StatusCode,
	}
	if err := json.Unmarshal(b, &e); err != nil {
		// this is not a regular error response:
		// populate detail with anything we received,
		// e.Status will already contain HTTP response code value
		e.Detail = string(b)
		if e.Detail == "" {
			e.Detail = resp.Status
		}
	}
	return &Error{
		StatusCode:  e.Status,
		ProblemType: e.Type,
		Detail:      e.Detail,
		Header:      resp.Header,
	}
}

// chainCert fetches CA certificate chain recursively by following "up" links.
// Each recursive call increments the depth by 1, resulting in an error
// if the recursion level reaches maxChainLen.
//
// First chainCert call starts with depth of 0.
func chainCert(ctx context.Context, client *http.Client, url string, depth int) ([][]byte, error) {
	if depth >= maxChainLen {
		return nil, errors.New("acme: certificate chain is too deep")
	}

	res, err := ctxhttp.Get(ctx, client, url)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return nil, responseError(res)
	}
	b, err := ioutil.ReadAll(io.LimitReader(res.Body, maxCertSize+1))
	if err != nil {
		return nil, err
	}
	if len(b) > maxCertSize {
		return nil, errors.New("acme: certificate is too big")
	}
	chain := [][]byte{b}

	uplink := linkHeader(res.Header, "up")
	if len(uplink) > maxChainLen {
		return nil, errors.New("acme: certificate chain is too large")
	}
	for _, up := range uplink {
		cc, err := chainCert(ctx, client, up, depth+1)
		if err != nil {
			return nil, err
		}
		chain = append(chain, cc...)
	}

	return chain, nil
}

// postJWS signs the body with the given key and POSTs it to the provided url.
// The body argument must be JSON-serializable.
func postJWS(ctx context.Context, client *http.Client, key crypto.Signer, url string, body interface{}) (*http.Response, error) {
	nonce, err := fetchNonce(ctx, client, url)
	if err != nil {
		return nil, err
	}
	b, err := jwsEncodeJSON(body, key, nonce)
	if err != nil {
		return nil, err
	}
	return ctxhttp.Post(ctx, client, url, "application/jose+json", bytes.NewReader(b))
}

func fetchNonce(ctx context.Context, client *http.Client, url string) (string, error) {
	resp, err := ctxhttp.Head(ctx, client, url)
	if err != nil {
		return "", nil
	}
	defer resp.Body.Close()
	enc := resp.Header.Get("replay-nonce")
	if enc == "" {
		return "", errors.New("acme: nonce not found")
	}
	return enc, nil
}

// linkHeader returns URI-Reference values of all Link headers
// with relation-type rel.
// See https://tools.ietf.org/html/rfc5988#section-5 for details.
func linkHeader(h http.Header, rel string) []string {
	var links []string
	for _, v := range h["Link"] {
		parts := strings.Split(v, ";")
		for _, p := range parts {
			p = strings.TrimSpace(p)
			if !strings.HasPrefix(p, "rel=") {
				continue
			}
			if v := strings.Trim(p[4:], `"`); v == rel {
				links = append(links, strings.Trim(parts[0], "<>"))
			}
		}
	}
	return links
}

func retryAfter(v string) (time.Duration, error) {
	if i, err := strconv.Atoi(v); err == nil {
		return time.Duration(i) * time.Second, nil
	}
	t, err := http.ParseTime(v)
	if err != nil {
		return 0, err
	}
	return t.Sub(timeNow()), nil
}

// keyAuth generates a key authorization string for a given token.
func keyAuth(pub crypto.PublicKey, token string) (string, error) {
	th, err := JWKThumbprint(pub)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%s.%s", token, th), nil
}

// tlsChallengeCert creates a temporary certificate for TLS-SNI challenges
// with the given SANs.
func tlsChallengeCert(san ...string) (tls.Certificate, error) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return tls.Certificate{}, err
	}
	t := x509.Certificate{
		SerialNumber:          big.NewInt(1),
		NotBefore:             time.Now(),
		NotAfter:              time.Now().Add(24 * time.Hour),
		BasicConstraintsValid: true,
		KeyUsage:              x509.KeyUsageKeyEncipherment,
		DNSNames:              san,
	}
	der, err := x509.CreateCertificate(rand.Reader, &t, &t, &key.PublicKey, key)
	return tls.Certificate{
		Certificate: [][]byte{der},
		PrivateKey:  key,
	}, nil
}

// encodePEM returns b encoded as PEM with block of type typ.
func encodePEM(typ string, b []byte) []byte {
	pb := &pem.Block{Type: typ, Bytes: b}
	return pem.EncodeToMemory(pb)
}

// timeNow is useful for testing for fixed current time.
var timeNow = time.Now
