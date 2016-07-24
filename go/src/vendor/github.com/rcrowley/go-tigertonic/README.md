Tiger Tonic
===========

[![Build Status](https://travis-ci.org/rcrowley/go-tigertonic.png?branch=master)](https://travis-ci.org/rcrowley/go-tigertonic)

A Go framework for building JSON web services inspired by [Dropwizard](http://www.dropwizard.io/).  If HTML is your game, this will hurt a little.

Like the Go language itself, Tiger Tonic strives to keep features orthogonal.  It defers what it can to the Go standard library and a few other packages.

Documentation
-------------

### Articles and talks

- Day 13 of Go Advent 2013: <http://blog.gopheracademy.com/day-13-tiger-tonic>
- Web Services in Go at GoSF 2014-01-15: video: <https://www.youtube.com/watch?v=D4CjdHllA-E>, slides: <http://rcrowley.org/talks/gosf-2014-01-15.html>
- GopherCon 2014 video: <http://confreaks.com/videos/3442-gophercon2014-building-web-services-in-go>, slides: <http://rcrowley.org/talks/gophercon-2014.html>

### Reference

<http://godoc.org/github.com/rcrowley/go-tigertonic>

### Community

- Users mailing list: <https://groups.google.com/forum/#!forum/tigertonic-users>
- Developers mailing list: <https://groups.google.com/forum/#!forum/tigertonic-dev>
- IRC: `#tigertonic` on `irc.freenode.net`

Synopsis
--------

### `tigertonic.TrieServeMux`

HTTP routing in the Go standard library is pretty anemic.  Enter `tigertonic.TrieServeMux`.  It accepts an HTTP method, a URL pattern, and an `http.Handler` or an `http.HandlerFunc`.  Components in the URL pattern wrapped in curly braces - `{` and `}` - are wildcards: their values (which don't cross slashes) are added to the URL as <code>u.Query().Get("<em>name</em>")</code>.

`HandleNamespace` is like `Handle` but additionally strips the namespace from the URL, making API versioning, multitenant services, and relative links easier to manage.  This is roughly equivalent to `http.ServeMux`'s behavior.

### `tigertonic.HostServeMux`

Use `tigertonic.HostServeMux` to serve multiple domain names from the same `net.Listener`.

### `tigertonic.Marshaled`

Wrap a function in `tigertonic.Marshaled` to turn it into an `http.Handler`.  The function signature must be something like this or `tigertonic.Marshaled` will panic:

```go
func myHandler(*url.URL, http.Header, *MyRequest) (int, http.Header, *MyResponse, error)
```

Request bodies will be unmarshaled into a `MyRequest` struct and response bodies will be marshaled from `MyResponse` structs.

Should you need to respond with an error, the `tigertonic.HTTPEquivError` interface is implemented by `tigertonic.BadRequest` (and so on for every other HTTP response status) that can be wrapped around any `error`:

```go
func myHandler(*url.URL, http.Header, *MyRequest) (int, http.Header, *MyResponse, error) {
    return 0, nil, nil, tigertonic.BadRequest{errors.New("Bad Request")}
}
```

Alternatively, you can return a valid status as the first output parameter and an `error` as the last; that status will be used in the error response.

If the return type of a `tigertonic.Marshaled` handler interface implements the `io.Reader` interface the stream will be written directly to the requestor. A `Content-Type` header is required to be specified in the response headers and the `Accept` header for these particular requests can be anything.

Additionally, if the return type of the `tigertonic.Marshaled` handler implements the `io.Closer` interface the stream will be automatically closed after it is flushed to the requestor.

### `tigertonic.Logged`, `tigertonic.JSONLogged`, and `tigertonic.ApacheLogged`

Wrap an `http.Handler` in `tigertonic.Logged` to have the request and response headers and bodies logged to standard output.  The second argument is an optional `func(string) string` called as requests and responses are logged to give the caller the opportunity to redact sensitive information from log entries.

Wrap an `http.Handler` in `tigertonic.JSONLogged` to have the request and response headers and bodies logged to standard output as JSON suitable for sending to ElasticSearch, Flume, Logstash, and so on.  The JSON will be prefixed with `@json: `.  The second argument is an optional `func(string) string` called as requests and responses are logged to give the caller the opportunity to redact sensitive information from log entries.

Wrap an `http.Handler` in `tigertonic.ApacheLogged` to have the request and response logged in the more traditional Apache combined log format.

### `tigertonic.Counted` and `tigertonic.Timed`

Wrap an `http.Handler` in `tigertonic.Counted` or `tigertonic.Timed` to have the request counted or timed with [`go-metrics`](https://github.com/rcrowley/go-metrics).

### `tigertonic.CountedByStatus` and `tigertonic.CountedByStatusXX`

Wrap an `http.Handler` in `tigertonic.CountedByStatus` or `tigertonic.CountedByStatusXX` to have the response counted with [`go-metrics`](https://github.com/rcrowley/go-metrics) with a `metrics.Counter` for each HTTP status code or family of status codes (`1xx`, `2xx`, and so on).

### `tigertonic.First`

Call `tigertonic.First` with a variadic slice of `http.Handler`s.  It will call `ServeHTTP` on each in succession until the first one that calls `w.WriteHeader`.

### `tigertonic.If`

`tigertonic.If` expresses the most common use of `tigertonic.First` more naturally.  Call `tigertonic.If` with a `func(*http.Request) (http.Header, error)` and an `http.Handler`.  It will conditionally call the handler unless the function returns an error.  In that case, the error is used to create a response.

### `tigertonic.PostProcessed` and `tigertonic.TeeResponseWriter`

`tigertonic.PostProcessed` uses a `tigertonic.TeeResponseWriter` to record the response and call a `func(*http.Request, *http.Response)` after the response is written to the client to allow post-processing requests and responses.

### `tigertonic.HTTPBasicAuth`

Wrap an `http.Handler` in `tigertonic.HTTPBasicAuth`, providing a `map[string]string` of authorized usernames to passwords, to require the request include a valid `Authorization` header.

### `tigertonic.CORSHandler` and `tigertonic.CORSBuilder`

Wrap an `http.Handler` in `tigertonic.CORSHandler` (using `CORSBuilder.Build()`) to inject CORS-related headers. Currently only `Origin`-related headers (used for cross-origin browser requests) are supported.

### `tigertonic.Configure`

Call `tigertonic.Configure` to read and unmarshal a JSON configuration file into a configuration structure of your own design.  This is mere convenience and what you do with it after is up to you.

### `tigertonic.WithContext` and `tigertonic.Context`

Wrap an `http.Handler` and a zero value of any non-interface type in `tigertonic.WithContext` to enable per-request context.  Each request may call `tigertonic.Context` with the `*http.Request` in progress to get a pointer to the context which is of the type passed to `tigertonic.WithContext`.

### `tigertonic.Version`

Respond with a version string that may be set at compile-time.

Usage
-----

Install dependencies:

```sh
sh bootstrap.sh
```

Then define your service.  The working [example](https://github.com/rcrowley/go-tigertonic/tree/master/example) may be a more convenient place to start.

Requests that have bodies have types.  JSON is deserialized by adding `tigertonic.Marshaled` to your routes.

```go
type MyRequest struct {
	ID     string      `json:"id"`
	Stuff  interface{} `json:"stuff"`
}
```

Responses, too, have types.  JSON is serialized by adding `tigertonic.Marshaled` to your routes.

```go
type MyResponse struct {
	ID     string      `json:"id"`
	Stuff  interface{} `json:"stuff"`
}
```

Routes are just functions with a particular signature.  You control the request and response types.

```go
func myHandler(u *url.URL, h http.Header, *MyRequest) (int, http.Header, *MyResponse, error) {
    return http.StatusOK, nil, &MyResponse{"ID", "STUFF"}, nil
}
```

Wire it all up in `main.main`!

```go
mux := tigertonic.NewTrieServeMux()
mux.Handle("POST", "/stuff", tigertonic.Timed(tigertonic.Marshaled(myHandler), "myHandler", nil))
tigertonic.NewServer(":8000", tigertonic.Logged(mux, nil)).ListenAndServe()
```

Ready for more?  See the full [example](https://github.com/rcrowley/go-tigertonic/tree/master/example) which includes all of these handlers plus an example of how to use `tigertonic.Server` to stop gracefully.  Build it with `go build`, run it with `./example`, and test it out:

```sh
curl -H"Host: example.com" -sv "http://127.0.0.1:8000/1.0/stuff/ID"
curl -H"Host: example.com" -X"POST" -d'{"id":"ID","stuff":"STUFF"}' -sv "http://127.0.0.1:8000/1.0/stuff"
curl -H"Host: example.com" -X"POST" -d'{"id":"ID","stuff":"STUFF"}' -sv "http://127.0.0.1:8000/1.0/stuff/ID"
curl -H"Host: example.com" -sv "http://127.0.0.1:8000/1.0/forbidden"
```

WTF?
----

Dropwizard was named after <http://gunshowcomic.com/316> so Tiger Tonic was named after <http://gunshowcomic.com/338>.

If Tiger Tonic isn't your cup of tea, perhaps one of these fine tools suits you:

* <http://beego.me>
* <http://robfig.github.io/revel/>
* <https://code.google.com/p/gorest/>
* <https://github.com/bmizerany/pat>
* <https://github.com/emicklei/go-restful>
* <https://github.com/hoisie/web>
* <http://www.gorillatoolkit.org>
