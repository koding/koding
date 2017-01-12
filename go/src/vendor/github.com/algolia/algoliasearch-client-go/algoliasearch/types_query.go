package algoliasearch

type multipleQueriesRes struct {
	Results []MultipleQueryRes `json:"results"`
}

type MultipleQueryRes struct {
	Index string `json:"index"`
	QueryRes
}

type QueryRes struct {
	AroundLatLng          string `json:"aroundLatLng,omitempty"`
	AutomaticRadius       string `json:"automaticRadius,omitempty"`
	ExhaustiveFacetsCount bool   `json:"exhaustiveFacetsCount,omitempty"`
	Facets                Map    `json:"facets,omitempty"`
	FacetsStats           Map    `json:"facets_stats,omitempty"`
	Hits                  []Map  `json:"hits"`
	HitsPerPage           int    `json:"hitsPerPage"`
	Index                 string `json:"index,omitempty"`
	Length                int    `json:"length,omitempty"`
	Message               string `json:"message,omitempty"`
	NbHits                int    `json:"nbHits"`
	NbPages               int    `json:"nbPages"`
	Offset                int    `json:"offset,omitempty"`
	Page                  int    `json:"page"`
	Params                string `json:"params"`
	ParsedQuery           string `json:"parsedQuery,omitempty"`
	ProcessingTimeMS      int    `json:"processingTimeMS"`
	Query                 string `json:"query"`
	QueryAfterRemoval     string `json:"queryAfterRemoval,omitempty"`
	ServerUsed            string `json:"serverUsed,omitempty"`
	TimeoutCounts         bool   `json:"timeoutCounts,omitempty"`
	TimeoutHits           bool   `json:"timeoutHits,omitempty"`
}

type IndexedQuery struct {
	IndexName string
	Params    Map
}
