package rollbar

import (
	"net/http"
	"net/http/httptest"
	"net/url"
)

var (
	mux    = http.NewServeMux()
	server = httptest.NewServer(mux)
	client = NewClient("089bd80bbfc2450dbe7b4ea2a897a181")
)

func init() {
	res, _ := url.Parse(server.URL)
	client.Endpoint = res
}
