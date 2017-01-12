package algoliasearch

type BrowseRes struct {
	Cursor  string `json:"cursor"`
	Warning string `json:"warning,omitempty"`
	QueryRes
}
