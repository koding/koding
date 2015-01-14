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

	"github.com/koding/bongo"
	"github.com/koding/cache"
)

var (
	ErrFetch       = errors.New("could not fetch files")
	ErrTypeCast    = errors.New("type cast error")
	ErrCacheNotHit = errors.New("cache not hit")
	sitemapCache   *cache.MemoryTTL
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

func init() {
	sitemapCache = cache.NewMemoryWithTTL(CacheTTL)
	sitemapCache.StartGC(GCInterval)
}

func FetchRoot(w http.ResponseWriter, _ *http.Request) {
	rootSitemapKey := "root"
	filesByte, err := getFromCache(rootSitemapKey)
	if err == nil {
		handleSuccess(w, filesByte)
		return
	}

	if err != cache.ErrNotFound {
		handleError(w, err, "An error occurred while fetching sitemap from cache")
		return
	}

	sf := models.NewSitemapFile()

	files, err := sf.FetchAll()
	if err != nil {
		handleError(w, err, "An error occurred while fetching sitemap root")
		return
	}

	set := models.NewSitemapSet(files, config.MustGet().Hostname)

	res, err := xml.Marshal(set)
	if err != nil {
		handleError(w, err, "An error occurred while marshalling sitemap root")
		return
	}

	sitemapCache.Set(rootSitemapKey, res)

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

	file, err := getFromCache(fileName)
	if err == nil {
		handleSuccess(w, file)
		return
	}

	if err != cache.ErrNotFound {
		handleError(w, err, "An error occurred while fetching sitemap from cache")
		return
	}

	sf := models.NewSitemapFile()
	if err := sf.ByName(fileName); err != nil {
		if err == bongo.RecordNotFound {
			handleError(w, errors.New(fileName), "File not found")
			return
		}

		handleError(w, err, "An error occurred while fetching sitemap")
		return
	}

	if sf.Blob == nil || len(sf.Blob) == 0 {
		handleError(w, errors.New(fileName), "Empty sitemap content")
		return
	}

	sitemapCache.Set(fileName, sf.Blob)

	handleSuccess(w, sf.Blob)
}

func getFromCache(fileName string) ([]byte, error) {
	file, err := sitemapCache.Get(fileName)
	if err != nil {
		return nil, err
	}

	res, ok := file.([]byte)
	if !ok {
		return nil, ErrTypeCast
	}

	return res, nil
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
