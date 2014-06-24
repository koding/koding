package api

import (
	"encoding/xml"
	"errors"
	"net/http"
	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"
	"strings"

	"github.com/jinzhu/gorm"
	"github.com/rcrowley/go-tigertonic"

	"github.com/koding/bongo"
)

var ErrFetch = errors.New("could not fetch files")

type SitemapHandler struct{}

// TODO wrap this TrieServeMux
func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	// list notifications
	// mux.Handle("GET", "/sitemap.xml", handler.XMLWrapper(&SitemapHandler{}, "sitemap"))
	mux.HandleFunc("GET", "/sitemap.xml", Generate)

	mux.HandleFunc("GET", "/sitemap/{name}", Fetch)

	return mux
}

func Generate(w http.ResponseWriter, _ *http.Request) {
	sf := new(models.SitemapFile)

	files := make([]models.SitemapFile, 0)
	query := &bongo.Query{}

	if err := sf.Some(&files, query); err != nil {
		helper.MustGetLogger().Error("An error occurred while fetching files: %s", err)
		http.Error(w, ErrFetch.Error(), http.StatusInternalServerError)
		return //response.NewBadRequest(ErrFetch)
	}

	set := models.NewSitemapSet(files, config.Get().Uri)

	res, err := common.Marshal(set)
	if err != nil {
		helper.MustGetLogger().Error("An error occurred while marshaling files: %s", err)
		http.Error(w, ErrFetch.Error(), http.StatusInternalServerError)
		return //response.NewBadRequest(ErrFetch)
	}

	w.Header().Set("Content-Type", "application/xml")
	w.Write(res)
}

func Fetch(w http.ResponseWriter, r *http.Request) {
	fileName := r.URL.Query().Get("name")
	names := strings.Split(fileName, ".")
	if len(names) == 0 {
		helper.MustGetLogger().Error("Name does not validated: %s", fileName)
		http.Error(w, ErrFetch.Error(), http.StatusBadRequest)
		return
	}

	fileName = names[0]
	sf := new(models.SitemapFile)
	if err := sf.ByName(fileName); err != nil {
		if err == gorm.RecordNotFound {
			helper.MustGetLogger().Error("File not found: %s", fileName)
			http.Error(w, ErrFetch.Error(), http.StatusBadRequest)
			return
		}
	}

	if sf.Blob == nil || len(sf.Blob) == 0 {
		helper.MustGetLogger().Error("Blob empty: %s", fileName)
		http.Error(w, ErrFetch.Error(), http.StatusBadRequest)
		return
	}

	header := []byte(xml.Header)
	w.Header().Set("Content-Type", "application/xml")
	w.Write(append(header, sf.Blob...))
}
