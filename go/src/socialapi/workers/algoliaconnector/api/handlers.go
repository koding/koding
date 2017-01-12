package api

import (
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/logging"
)

type Handler struct {
	client        algoliasearch.Client
	logger        logging.Logger
	searchOnlyKey string
}

func NewHandler(c algoliasearch.Client, l logging.Logger, searchOnlyKey string) *Handler {
	return &Handler{
		client:        c,
		logger:        l,
		searchOnlyKey: searchOnlyKey,
	}

}

func AddHandlers(m *mux.Mux, l logging.Logger) {
	algoliaConf := config.MustGet().Algolia
	c := algoliasearch.NewClient(algoliaConf.AppId, algoliaConf.ApiSecretKey)

	h := NewHandler(c, l, algoliaConf.ApiSearchOnlyKey)
	m.AddHandler(
		handler.Request{
			Handler:  h.GenerateKey,
			Type:     handler.GetRequest,
			Endpoint: "/search-key",
		})

}
