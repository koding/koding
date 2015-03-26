package api

import (
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/logging"
	"github.com/koding/metrics"
)

type Handler struct {
	client *algoliasearch.Client
	logger logging.Logger
	apiKey string
}

func NewHandler(c *algoliasearch.Client, l logging.Logger, apiKey string) *Handler {
	return &Handler{
		client: c,
		logger: l,
		apiKey: apiKey,
	}

}

func AddHandlers(m *mux.Mux, metric *metrics.Metrics, l logging.Logger) {
	algoliaConf := config.MustGet().Algolia
	c := algoliasearch.NewClient(algoliaConf.AppId, algoliaConf.ApiSecretKey)

	h := NewHandler(c, l, algoliaConf.ApiTokenKey)
	m.AddHandler(
		handler.Request{
			Handler:  h.GenerateKey,
			Type:     handler.GetRequest,
			Endpoint: "/search-key",
			Metrics:  metric,
		})

}
