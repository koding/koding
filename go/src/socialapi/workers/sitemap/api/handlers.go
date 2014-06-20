package api

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path"
	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"

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
	wd, err := os.Getwd()
	if err != nil {
		return
	}
	fileName := r.URL.Query().Get("name")

	n := path.Join(wd, config.Get().Sitemap.XMLRoot, fileName)
	if _, err := os.Stat(n); os.IsNotExist(err) {
		helper.MustGetLogger().Error("File not found: %s", n)
		http.Error(w, ErrFetch.Error(), http.StatusBadRequest)
		return
	}
	input, err := ioutil.ReadFile(n)
	if err != nil {
		helper.MustGetLogger().Error("File cannot be read: %s", err)
		http.Error(w, ErrFetch.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/xml")
	w.Write(input)
}

func (h *SitemapHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("request %+v \n", r)
	sf := new(models.SitemapFile)

	files := make([]models.SitemapFile, 0)
	query := &bongo.Query{}

	if err := sf.Some(&files, query); err != nil {
		helper.MustGetLogger().Error("An error occurred while fetching files: %s", err)
		return //response.NewBadRequest(ErrFetch)
	}

	set := models.NewSitemapSet(files, config.Get().Uri)

	res, err := common.Marshal(set)
	if err != nil {
		helper.MustGetLogger().Error("An error occurred while marshaling files: %s", err)
		return //response.NewBadRequest(ErrFetch)
	}

	w.Header().Set("Content-Type", "application/xml")
	w.Write(res)
}
