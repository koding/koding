package algoliasearch

type FacetHit struct {
	Value       string `json:"value"`
	Highlighted string `json:"highlighted"`
	Count       int    `json:"count"`
}

type SearchFacetRes struct {
	FacetHits        []FacetHit `json:"facetHits"`
	ProcessingTimeMS int        `json:"processingTimeMS"`
}
