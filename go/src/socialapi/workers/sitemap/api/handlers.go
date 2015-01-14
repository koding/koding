package api

import (
	"encoding/xml"
	"errors"
	"net/http"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/models"
	"strings"
	"time"
)

var (
	ErrFetch = errors.New("could not fetch files")
	cache    *models.SitemapFileCache
)

const (
	CacheTTL   = 5 * time.Minute
	GCInterval = 30 * time.Second
)

type ErrorResponse struct {
	XMLName xml.Name `xml:"response"`
	Error   string   `xml:"error"`
}

func AddHandlers(m *mux.Mux) {
	m.AddUnscopedHandler(
		handler.Request{
			Handler:  FetchRoot,
			Type:     handler.GetRequest,
			Endpoint: "/sitemap.xml",
		})

	m.AddUnscopedHandler(
		handler.Request{
			Handler:  FetchByName,
			Type:     handler.GetRequest,
			Endpoint: "/sitemap/{name}",
		})
}

func NewDefaultError(err error) []byte {
	res, _ := xml.Marshal(&ErrorResponse{Error: err.Error()})

	return res
}

func getCache() *models.SitemapFileCache {
	if cache == nil {
		cache = models.NewSitemapFileCache(CacheTTL, GCInterval, config.MustGet().Hostname)
	}

	return cache
}

func FetchRoot(w http.ResponseWriter, _ *http.Request) {
	res, err := getCache().FetchRoot()
	if err != nil {
		handleError(w, err, "An error occurred while fetching sitemap")
		return
	}

	handleSuccess(w, res)
}

func FetchByName(w http.ResponseWriter, r *http.Request) {
	fileName := r.URL.Query().Get("name")

	names := strings.Split(fileName, ".")
	if len(names) == 0 {
		handleError(w, errors.New(fileName), "Invalid sitemap name")
		return
	}

	fileName = names[0]

	res, err := getCache().FetchByName(fileName)
	if err != nil {
		handleError(w, err, "An error occurred while fetching sitemap")
		return
	}

	handleSuccess(w, res)
}

func appendXmlHeader(data []byte) []byte {
	header := []byte(xml.Header)

	return append(header, data...)
}

func handleError(w http.ResponseWriter, err error, errMessage string) {
	helper.MustGetLogger().Error("%s: %s", errMessage, err)
	w.Header().Set("Content-Type", "application/xml")
	w.Write(NewDefaultError(ErrFetch))
}

func handleSuccess(w http.ResponseWriter, data []byte) {
	w.Header().Set("Content-Type", "application/xml")
	// append default xml header to the result set with UTF-8 encoding
	w.Write(appendXmlHeader(data))
}
