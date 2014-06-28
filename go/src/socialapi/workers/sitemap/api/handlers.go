package api

import (
	"encoding/xml"
	"errors"
	"net/http"
	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/models"
	"strings"

	"github.com/rcrowley/go-tigertonic"

	"github.com/koding/bongo"
)

var ErrFetch = errors.New("could not fetch files")

type SitemapHandler struct{}

type ErrorResponse struct {
	XMLName xml.Name `xml:"response"`
	Error   string   `xml:"error"`
}

func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	mux.HandleFunc("GET", "/sitemap.xml", Generate)

	mux.HandleFunc("GET", "/sitemap/{name}", Fetch)

	return mux
}

func NewDefaultError(err error) []byte {
	res, _ := marshal(&ErrorResponse{Error: err.Error()})
	return res
}

func Generate(w http.ResponseWriter, _ *http.Request) {
	sf := models.NewSitemapFile()

	files := make([]models.SitemapFile, 0)
	query := &bongo.Query{}

	if err := sf.Some(&files, query); err != nil {
		helper.MustGetLogger().Error("An error occurred while fetching files: %s", err)
		w.Write(NewDefaultError(ErrFetch))
		return
	}

	set := models.NewSitemapSet(files, config.MustGet().Uri)

	res, err := marshal(set)
	if err != nil {
		helper.MustGetLogger().Error("An error occurred while marshalling files: %s", err)
		w.Write(NewDefaultError(ErrFetch))
		return
	}

	w.Header().Set("Content-Type", "application/xml")
	w.Write(res)
}

func Fetch(w http.ResponseWriter, r *http.Request) {
	fileName := r.URL.Query().Get("name")
	names := strings.Split(fileName, ".")
	if len(names) == 0 {
		helper.MustGetLogger().Error("Name does not validated: %s", fileName)
		w.Write(NewDefaultError(ErrFetch))
		return
	}

	fileName = names[0]
	sf := models.NewSitemapFile()
	if err := sf.ByName(fileName); err != nil {
		if err == bongo.RecordNotFound {
			helper.MustGetLogger().Error("File not found: %s", fileName)
			w.Write(NewDefaultError(ErrFetch))
			return
		}
	}

	if sf.Blob == nil || len(sf.Blob) == 0 {
		helper.MustGetLogger().Error("Blob empty: %s", fileName)
		w.Write(NewDefaultError(ErrFetch))
		return
	}

	// append default xml header to the result set with UTF-8 encoding
	header := []byte(xml.Header)
	w.Header().Set("Content-Type", "application/xml")
	w.Write(append(header, sf.Blob...))
}

func marshal(i interface{}) ([]byte, error) {
	header := []byte(xml.Header)
	res, err := xml.Marshal(i)
	if err != nil {
		return nil, err
	}
	// append header to xml file
	return append(header, res...), nil
}
