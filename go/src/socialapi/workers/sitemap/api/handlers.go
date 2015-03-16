package api

import (
	"encoding/xml"
	"errors"
	"net/http"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/sitemap/models"
	"strings"
	"time"

	"github.com/koding/runner"
)

var ErrFetch = errors.New("could not fetch files")

const (
	CacheTTL   = 5 * time.Minute
	GCInterval = 30 * time.Second
)

type ErrorResponse struct {
	XMLName xml.Name `xml:"response"`
	Error   string   `xml:"error"`
}

type SitemapHandler struct {
	fetcher *models.SitemapFetcher
}

func NewSitemapHandler() *SitemapHandler {
	return &SitemapHandler{
		fetcher: models.NewSitemapFetcher(CacheTTL, GCInterval, config.MustGet().Hostname),
	}
}

func AddHandlers(m *mux.Mux) {
	sh := NewSitemapHandler()

	m.AddUnscopedHandler(
		handler.Request{
			Handler:  sh.FetchRoot,
			Type:     handler.GetRequest,
			Endpoint: "/sitemap.xml",
		})

	m.AddUnscopedHandler(
		handler.Request{
			Handler:  sh.FetchByName,
			Type:     handler.GetRequest,
			Endpoint: "/sitemap/{name}",
		})
}

func NewDefaultError(err error) []byte {
	res, _ := xml.Marshal(&ErrorResponse{Error: err.Error()})

	return res
}

func (sh *SitemapHandler) FetchRoot(w http.ResponseWriter, _ *http.Request) {
	res, err := sh.fetcher.FetchRoot()
	if err != nil {
		handleError(w, err, "An error occurred while fetching sitemap")
		return
	}

	handleSuccess(w, res)
}

func (sh *SitemapHandler) FetchByName(w http.ResponseWriter, r *http.Request) {
	fileName := r.URL.Query().Get("name")

	names := strings.Split(fileName, ".")
	if len(names) == 0 {
		handleError(w, errors.New(fileName), "Invalid sitemap name")
		return
	}

	fileName = names[0]

	res, err := sh.fetcher.FetchByName(fileName)
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
	runner.MustGetLogger().Error("%s: %s", errMessage, err)
	w.Header().Set("Content-Type", "application/xml")
	w.Write(NewDefaultError(ErrFetch))
}

func handleSuccess(w http.ResponseWriter, data []byte) {
	w.Header().Set("Content-Type", "application/xml")
	// append default xml header to the result set with UTF-8 encoding
	w.Write(appendXmlHeader(data))
}
