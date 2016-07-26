package clearbit

import "net/http"

type clearbit struct {
	apiKey     string
	client     *http.Client
	enrichment Enrichment
}

func (c *clearbit) Enrichment() Enrichment {
	return c.enrichment
}
