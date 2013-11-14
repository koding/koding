package cache

import (
	"bufio"
	"bytes"
	"fmt"
	"github.com/fatih/goset"
	"net/http"
	"net/http/httputil"
	"strings"
	"sync"
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
	fmt.Println("err", err)
	if err == nil {
		fmt.Printf("==== GET CACHE ====: '%s'\n", c.cacheKey(req))
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
	fmt.Println("loading from cache key", key)
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

	fmt.Printf("==== SAVE CACHE ====: '%s'\n", key)
	c.cache.Set(key, respBytes)
	return nil
}

type MemoryCache struct {
	sync.RWMutex
	items map[string][]byte
}

func NewMemoryCache() *MemoryCache {
	return &MemoryCache{
		items: map[string][]byte{},
	}
}

func (c *MemoryCache) Get(key string) ([]byte, bool) {
	c.RLock()
	defer c.RUnlock()

	value, ok := c.items[key]
	return value, ok
}

func (c *MemoryCache) Set(key string, resp []byte) {
	c.Lock()
	defer c.Unlock()

	c.items[key] = resp
}

func (c *MemoryCache) Delete(key string) {
	c.Lock()
	defer c.Unlock()

	delete(c.items, key)
}
