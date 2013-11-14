package cache

import (
	"bufio"
	"bytes"
	"fmt"
	"github.com/fatih/goset"
	"net/http"
	"net/http/httputil"
	"path/filepath"
	"strings"
)

// Cache interface is used by CacheTransport to store and retrieve the cache content.
type Cache interface {
	Get(key string) ([]byte, bool)
	Set(key string, value []byte)
	Delete(key string)
}

type CacheTransport struct {
	cache     Cache
	transport http.RoundTripper
	suffixes  *goset.Set
}

func NewCacheTransport(suffixes string) http.RoundTripper {
	set := goset.New()

	for _, suffix := range strings.Split(suffixes, ",") {
		set.Add(strings.TrimSpace(suffix))
	}

	return &CacheTransport{
		cache:     NewMemoryCache(),
		transport: http.DefaultTransport,
		suffixes:  set,
	}
}

func (c *CacheTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if !c.cacheableRequest(req) {
		return c.transport.RoundTrip(req)
	}

	cache, err := c.load(req)
	if err == nil {
		return cache, nil
	}

	resp, err := c.transport.RoundTrip(req)
	if err != nil {
		return nil, err
	}

	if c.cacheableResponse(resp) {
		c.save(req, resp)
	}

	return resp, nil
}

func (c *CacheTransport) cacheKey(req *http.Request) string {
	return req.URL.String()
}

// cacheableRequest defines if a request is cachable. Only requests with GET
// methods and files that matches the cachePrefix rule is cached.
func (c *CacheTransport) cacheableRequest(req *http.Request) bool {
	if req.Method != "GET" {
		return false
	}

	suffix := filepath.Ext(req.URL.String())
	if suffix == "" {
		return false
	}

	// filepath.Ext returns .js for sample.js, therefore remove the dot
	if !c.suffixes.Has(suffix[1:]) {
		return false
	}

	return true
}

// cacheableResponse defines whether a response is cacheable or not.We only
// cache responses with 200. 301 and 302 are not cached currently.
func (c *CacheTransport) cacheableResponse(resp *http.Response) bool {
	return resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusNotModified
}

// load prepares the response of a request by loading its body from cache.
func (c *CacheTransport) load(req *http.Request) (*http.Response, error) {
	key := c.cacheKey(req)
	cachedResp, ok := c.cache.Get(key)
	if !ok {
		return nil, fmt.Errorf("cache is not available for: %s", key)
	}

	b := bytes.NewBuffer(cachedResp)
	return http.ReadResponse(bufio.NewReader(b), req)
}

// save saves the body of a response corresponding to a request.
func (c *CacheTransport) save(req *http.Request, resp *http.Response) error {
	key := c.cacheKey(req)
	respBytes, err := httputil.DumpResponse(resp, true)
	if err != nil {
		return err
	}

	c.cache.Set(key, respBytes)
	return nil
}
