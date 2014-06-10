package sockjs

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"time"
)

var entropy *rand.Rand

func init() {
	entropy = rand.New(rand.NewSource(time.Now().UnixNano()))
}

// Options type is used for defining various sockjs options
type Options struct {
	HeartbeatDelay  time.Duration
	DisconnectDelay time.Duration
	SockJSURL       string
	Websocket       bool
	CookieNeeded    bool
	ResponseLimit   uint32
}

// DefaultOptions is a convenient set of options to be used for sockjs
var DefaultOptions = Options{
	Websocket:       true,
	CookieNeeded:    false,
	SockJSURL:       "http://cdn.sockjs.org/sockjs-0.3.min.js",
	HeartbeatDelay:  2 * time.Second,
	DisconnectDelay: 5 * time.Second,
	ResponseLimit:   128 * 1024,
}

type info struct {
	Websocket    bool     `json:"websocket"`
	CookieNeeded bool     `json:"cookie_needed"`
	Origins      []string `json:"origins"`
	Entropy      int32    `json:"entropy"`
}

func (options *Options) info(rw http.ResponseWriter, req *http.Request) {
	switch req.Method {
	case "GET":
		rw.Header().Set("Content-Type", "application/json; charset=UTF-8")
		json.NewEncoder(rw).Encode(info{
			Websocket:    options.Websocket,
			CookieNeeded: options.CookieNeeded,
			Origins:      []string{"*:*"},
			Entropy:      entropy.Int31(),
		})
	case "OPTIONS":
		rw.Header().Set("Access-Control-Allow-Methods", "OPTIONS, GET")
		rw.Header().Set("Access-Control-Max-Age", fmt.Sprintf("%d", 365*24*60*60))
		rw.WriteHeader(http.StatusNoContent) // 204
	default:
		http.NotFound(rw, req)
	}
}

func (options *Options) cookie(rw http.ResponseWriter, req *http.Request) {
	if options.CookieNeeded { // cookie is needed
		cookie, err := req.Cookie("JSESSIONID")
		if err == http.ErrNoCookie {
			cookie = &http.Cookie{
				Name:  "JSESSIONID",
				Value: "dummy",
			}
		}
		cookie.Path = "/"
		header := rw.Header()
		header.Add("Set-Cookie", cookie.String())
	}
}
