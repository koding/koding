package clearbit

import "net/http"

type Clearbit interface {
	Enrichment() Enrichment
}

func New(apiKey string) Clearbit {
	c := &clearbit{
		apiKey: apiKey,
		client: http.DefaultClient,
	}
	c.enrichment = &enrichment{
		clearbit: c,
	}
	return c
}
