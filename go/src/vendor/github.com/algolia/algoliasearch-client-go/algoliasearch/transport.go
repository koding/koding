package algoliasearch

import (
	"bytes"
	_ "crypto/sha512" // Fix certificates
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	version = "2.7.0"
)

// Define the constants used to specify the type of request.
const (
	search = 1 << iota
	write
	read
)

// Seed the RNG used to shuffle the hosts slice (see `defaultHosts` function).
func init() {
	rand.Seed(int64(time.Now().Nanosecond()))
}

// Transport is responsible for the connection and the retry strategy to
// Algolia servers.
type Transport struct {
	activeReadHost    string
	activeReadSince   time.Time
	activeWriteHost   string
	activeWriteSince  time.Time
	apiKey            string
	appId             string
	dialTimeout       time.Duration
	headers           map[string]string
	hosts             []string
	httpClient        *http.Client
	keepAliveDuration time.Duration
}

// NewTransport instantiates a new Transport with the default Algolia hosts to
// connect to.
func NewTransport(appId, apiKey string) *Transport {
	return &Transport{
		activeReadHost:    "",
		activeWriteHost:   "",
		apiKey:            apiKey,
		appId:             appId,
		dialTimeout:       1 * time.Second,
		headers:           defaultHeaders(appId, apiKey),
		hosts:             defaultHosts(appId),
		httpClient:        defaultHttpClient(),
		keepAliveDuration: 5 * 60 * time.Second,
	}
}

// NewTransport instantiates a new Transport with the specificed hosts as main
// servers to connect to.
func NewTransportWithHosts(appId, apiKey string, hosts []string) *Transport {
	return &Transport{
		activeReadHost:    "",
		activeWriteHost:   "",
		apiKey:            apiKey,
		appId:             appId,
		dialTimeout:       1 * time.Second,
		headers:           defaultHeaders(appId, apiKey),
		hosts:             hosts,
		httpClient:        defaultHttpClient(),
		keepAliveDuration: 5 * 60 * time.Second,
	}
}

// defaultHeaders is used to set the default HTTP headers to use with each
// requests.
func defaultHeaders(appId, apiKey string) map[string]string {
	return map[string]string{
		"Connection":               "keep-alive",
		"User-Agent":               "Algolia for Go (" + version + ")",
		"X-Algolia-API-Key":        apiKey,
		"X-Algolia-Application-Id": appId,
	}
}

// defaultHosts returns the list of the default Algolia hosts to use. The
// entries are shuffled.
func defaultHosts(appId string) []string {
	hosts := []string{
		appId + "-1.algolianet.com",
		appId + "-2.algolianet.com",
		appId + "-3.algolianet.com",
	}

	shuffled := make([]string, len(hosts))
	for i, v := range rand.Perm(len(hosts)) {
		shuffled[i] = hosts[v]
	}

	return shuffled
}

// defaultHttpClient returns the `*http.Client` which will perform all the
// requests. All the timeout settings are explicitely defined here.
func defaultHttpClient() *http.Client {
	return &http.Client{
		Timeout:   time.Second * 30,
		Transport: defaultTransport(1 * time.Second),
	}
}

// defaultTransport returns the `*http.Transport` which starts and maintain the
// connection with the server. The `dialTimeout` is used to specify the timeout
// beyond which the connection is considered as failed (used to control DNS
// lookup timeouts).
func defaultTransport(dialTimeout time.Duration) *http.Transport {
	return &http.Transport{
		Dial: (&net.Dialer{
			KeepAlive: 180 * time.Second,
			Timeout:   dialTimeout,
		}).Dial,
		DisableKeepAlives:   false,
		MaxIdleConnsPerHost: 2,
		TLSHandshakeTimeout: 2 * time.Second,
	}
}

// addHeaders add the key/value pairs from `headers` to the header list of the
// `req` request.
func addHeaders(req *http.Request, headers map[string]string) {
	for k, v := range headers {
		req.Header.Add(k, v)
	}
}

// setExtraHeader lets the user (through the exported `Client.SetExtraHeader`)
// add custom headers to the requests.
func (t *Transport) setExtraHeader(key, value string) {
	t.headers[key] = value
}

// setTimeout lets the user (through the exported `Client.SetTimeout`) replace
// the default values of `TLSHandshakeTimeout` (via `connectTimeout`) and
// `ResponseHeaderTimeout` (via `readTimeout`).
func (t *Transport) setTimeout(connectTimeout, readTimeout time.Duration) {
	switch transport := t.httpClient.Transport.(type) {
	case *http.Transport:
		transport.TLSHandshakeTimeout = connectTimeout
		transport.ResponseHeaderTimeout = readTimeout
	default:
		fmt.Fprintln(os.Stderr, "Timeouts not set for nonstandard underlying Transport")
	}
}

// request is the method used by the `Client` to perform the request against
// the Algolia servers (or to the list of specified hosts).
func (t *Transport) request(method, path string, body interface{}, typeCall int) ([]byte, error) {
	var res []byte
	var err error

	for _, host := range t.hostsToTry(typeCall) {
		res, err = t.tryRequest(method, host, path, body)
		if err == nil {
			t.resetDialTimeout()
			if typeCall == write {
				t.activeWriteSince = time.Now()
				t.activeWriteHost = host
			} else {
				t.activeReadSince = time.Now()
				t.activeReadHost = host
			}
			return res, nil
		}
		t.increaseDialTimeout()
	}

	if typeCall == write {
		t.activeWriteHost = ""
	} else {
		t.activeReadHost = ""
	}

	return nil, err
}

// hostsToTry returns the list of hosts to try ordered by priority according to
// the type of request (write vs. read/search) and if a previous host was
// marked as active.
func (t *Transport) hostsToTry(typeCall int) []string {
	var hosts []string

	if typeCall == write {
		// In case the request is a write query, we put the last active write
		// host first in the list of hosts to try if it was used in the last
		// `keepAliveDuration` seconds. We then put the main algolia.net host.
		if t.activeWriteHost != "" &&
			t.activeWriteHost != t.appId+".algolia.net" &&
			time.Now().Sub(t.activeWriteSince) <= t.keepAliveDuration {
			hosts = []string{t.activeWriteHost}
		}
		hosts = append(hosts, t.appId+".algolia.net")
	} else {
		// In case the request is not a write query, we put the last active
		// read host first in the list of hosts to try if it was used in the
		// last `keepAliveDuration` seconds. We then put the DSN host.
		if t.activeReadHost != "" &&
			t.activeReadHost != t.appId+"-dsn.algolia.net" &&
			time.Now().Sub(t.activeReadSince) <= t.keepAliveDuration {
			hosts = []string{t.activeReadHost}
		}
		hosts = append(hosts, t.appId+"-dsn.algolia.net")
	}

	// In any case, we append all the original hosts (default ones or the ones
	// specified by the user) to the list of hosts to try.
	hosts = append(hosts, t.hosts...)
	return hosts

}

// tryRequest is the underlying method which actually performs the request. It
// returns the response as a byte slice or a non-nil error if anything went
// wrong.
func (t *Transport) tryRequest(method, host, path string, body interface{}) ([]byte, error) {
	// Build the request
	req, err := t.buildRequest(method, host, path, body)
	if err != nil {
		return nil, err
	}

	// Perform the request
	res, err := t.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("Cannot perform request [%s] %s (%s): %s", method, path, host, err)
	}

	// Read response's body
	bodyRes, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return nil, fmt.Errorf("Cannot read response body: %s", err)
	}
	res.Body.Close()

	// Return the body as an error if the status code is not 2XX
	code := res.StatusCode
	if !(200 <= code && code < 300) {
		return nil, errors.New(string(bodyRes))
	}

	return bodyRes, nil
}

// buildRequest returns a valid `http.Request` with the headers and body (if
// any) correctly set. The return error is non-nil if the request is invalid or
// if the body, if non-nil, is not a valid JSON.
func (t *Transport) buildRequest(method, host, path string, body interface{}) (*http.Request, error) {
	var req *http.Request
	var err error
	urlStr := "https://" + host + path

	if body == nil {
		// As the body is nil, an empty body request is instantiated
		req, err = http.NewRequest(method, urlStr, nil)
		if err != nil {
			return nil, fmt.Errorf("Cannot instantiate request: [%s] %s", method, urlStr)
		}
	} else {
		// As the body is non-nil, the content is read
		data, err := json.Marshal(body)
		if err != nil {
			return nil, errors.New("Invalid JSON in the query")
		}
		reader := bytes.NewReader(data)

		// The request is then instantiated with the body content
		req, err = http.NewRequest(method, urlStr, reader)
		if err != nil {
			return nil, fmt.Errorf("Cannot instantiate request: [%s] %s", method, urlStr)
		}

		// Add content specific headers
		req.Header.Add("Content-Length", strconv.Itoa(len(string(data))))
		req.Header.Add("Content-Type", "application/json; charset=utf-8")
	}

	// Add default and Algolia specific headers
	addHeaders(req, t.headers)

	if strings.Contains(path, "/*/") {
		req.URL = &url.URL{
			Scheme: "https",
			Host:   host,
			Opaque: "//" + host + path, //Remove url encoding
		}
	}

	return req, nil
}

// resetDialTimeout increases the `Timeout` value of the underlying dialer by 1
// second.
func (t *Transport) increaseDialTimeout() {
	t.dialTimeout = t.dialTimeout + time.Second
	t.httpClient.Transport = defaultTransport(t.dialTimeout)
}

// resetDialTimeout resets the `Timeout` value of the underlying dialer to 1
// second.
func (t *Transport) resetDialTimeout() {
	t.dialTimeout = 1 * time.Second
	t.httpClient.Transport = defaultTransport(t.dialTimeout)
}
