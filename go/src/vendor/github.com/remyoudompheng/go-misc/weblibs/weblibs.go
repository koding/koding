// Package weblibs gives a convenient way to serve common JS frameworks.
package weblibs

import (
	"archive/zip"
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/remyoudompheng/go-misc/zipfs"
)

const (
	JQUERY_VERSION = "1.8.3"
	JQUERY_URL     = "http://code.jquery.com/jquery-" + JQUERY_VERSION + ".min.js"

	BOOTSTRAP_URL = "https://github.com/twbs/bootstrap/releases/download/v3.0.0/bootstrap-3.0.0-dist.zip"
)

// RegisterAll registers:
// - jquery at /libs/jquery.min.js
// - bootstrap at /libs/bootstrap/{css,js,img}
func RegisterAll(mux *http.ServeMux) error {
	if mux == nil {
		mux = http.DefaultServeMux
	}
	h, err := HandleJquery()
	if err != nil {
		return fmt.Errorf("could not prepare jquery: %s", err)
	}
	mux.Handle("/libs/jquery.min.js", h)
	h, err = HandleBootstrap()
	if err != nil {
		return fmt.Errorf("could not prepare Bootstrap: %s", err)
	}
	mux.Handle("/libs/bootstrap/", http.StripPrefix("/libs/bootstrap", addPrefix("/dist", h)))
	return nil
}

func addPrefix(p string, h http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		req.URL.Path = p + req.URL.Path
		h.ServeHTTP(w, req)
	}
}

type ContentHandler []byte

func (c ContentHandler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	w.Write(c)
}

func HandleJquery() (http.Handler, error) {
	resp, err := http.Get(JQUERY_URL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	js, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("can't read body: %s", err)
	}
	return ContentHandler(js), nil
}

func HandleBootstrap() (http.Handler, error) {
	resp, err := http.Get(BOOTSTRAP_URL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	z, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("can't read body: %s", err)
	}
	zr, err := zip.NewReader(bytes.NewReader(z), int64(len(z)))
	if err != nil {
		return nil, fmt.Errorf("can't parse zip archive: %s", err)
	}
	return http.FileServer(zipfs.NewZipFS(zr)), nil
}
