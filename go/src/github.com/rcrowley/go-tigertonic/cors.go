package tigertonic

import (
	"log"
	"net/http"
	"strings"
)

const (
	CORSRequestOrigin  string = "Origin"
	CORSRequestMethod  string = "Access-Control-Request-Method"
	CORSRequestHeaders string = "Access-Control-Request-Headers"
)

const (
	CORSAllowOrigin      string = "Access-Control-Allow-Origin"
	CORSAllowMethods     string = "Access-Control-Allow-Methods"
	CORSAllowHeaders     string = "Access-Control-Allow-Headers"
	CORSExposeHeaders    string = "Access-Control-Expose-Headers"
	CORSAllowCredentials string = "Access-Control-Allow-Credentials"
)

// CORSHandler wraps an http.Handler while correctly handling CORS related
// functionality, such as Origin headers. It also allows tigertonic core to
// correctly respond to OPTIONS headers for CORS-enabled endpoints
type CORSHandler struct {
	http.Handler
	origins                     map[string]bool
	allowHeaders, exposeHeaders string
	allowCredentials            bool
}

func (self *CORSHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	self.HandleCORS(w, r)
	self.Handler.ServeHTTP(w, r)
}

// HandleCORS checks for CORS related request headers and writes the
// matching response headers for both OPTIONS and regular requests
func (self *CORSHandler) HandleCORS(w http.ResponseWriter, r *http.Request) {
	if requestOrigin := r.Header.Get(CORSRequestOrigin); requestOrigin != "" {
		allowedOrigin := self.allowedOrigin(requestOrigin)
		if self.allowCredentials && allowedOrigin == requestOrigin {
			w.Header().Set(CORSAllowCredentials, self.allowsCredentials())
		}
		w.Header().Set(CORSAllowOrigin, allowedOrigin)
	}
	if requestHeaders := r.Header.Get(CORSRequestHeaders); requestHeaders != "" {
		w.Header().Set(CORSAllowHeaders, self.allowedHeaders())
	}
	w.Header().Set(CORSExposeHeaders, self.exposedHeaders())
}

func (self *CORSHandler) allowsCredentials() string {
	if self.allowCredentials {
		return "true"
	}
	return ""
}

// allowedOrigin checks if the requested origin is allowed by the configuration
// and returns a value that makes sense in context. It's less straight forward
// than allowedHeaders due to browser quirks. See the following excellent doc
// for more information: http://enable-cors.org/server_nginx.html
func (self *CORSHandler) allowedOrigin(requestOrigin string) string {
	if len(self.origins) == 1 && self.origins["*"] {
		return "*"
	} else if self.origins[requestOrigin] {
		return requestOrigin
	}
	return "null"
}

// allowedHeaders simply returns the headers permitted on requests
func (self *CORSHandler) allowedHeaders() string {
	return self.allowHeaders
}

// exposedHeaders simply returns the headers permitted on responses
func (self *CORSHandler) exposedHeaders() string {
	return self.exposeHeaders
}

// CORSBuilder facilitates the application of the same set of CORS rules to a
// number of endpoints. One would use CORSBuilder.Build() the same way one
// might wrap a handler in a call to Timed() or Logged().
type CORSBuilder struct {
	origins                     map[string]bool
	allowHeaders, exposeHeaders []string
	allowCredentials            bool
}

func NewCORSBuilder() *CORSBuilder {
	return &CORSBuilder{map[string]bool{}, []string{}, []string{}, false}
}

// AddAllowedOrigins sets the list of  domain for which cross-origin
// requests are allowed
func (self *CORSBuilder) AddAllowedOrigins(origins ...string) *CORSBuilder {
	for _, origin := range origins {
		if origin == "*" {
			if len(origins)+len(self.origins) > 1 {
				log.Println("WARNING: Setting CORS allowed origin * as well as other explicit origins. * will cause all origins to be accepted, and the rest of the list will be ignored. This is probably not what you want.")
			}
			self.origins = map[string]bool{"*": true}
			break
		}
		self.origins[origin] = true
	}
	return self
}

func (self *CORSBuilder) AddAllowedHeaders(headers ...string) *CORSBuilder {
	self.allowHeaders = append(self.allowHeaders, headers...)
	return self
}

func (self *CORSBuilder) AddAllowCredentials(allowed bool) *CORSBuilder {
	self.allowCredentials = allowed
	return self
}

func (self *CORSBuilder) AddExposedHeaders(headers ...string) *CORSBuilder {
	self.exposeHeaders = append(self.exposeHeaders, headers...)
	return self
}

func (self *CORSBuilder) Build(handler http.Handler) *CORSHandler {
	return &CORSHandler{handler, self.origins, strings.Join(self.allowHeaders, ", "), strings.Join(self.exposeHeaders, ", "), self.allowCredentials}
}
