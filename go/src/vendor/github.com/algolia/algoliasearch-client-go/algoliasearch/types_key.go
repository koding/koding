package algoliasearch

type Key struct {
	ACL                    []string `json:"acl"`
	CreatedAt              int      `json:"createdAt,omitempty"`
	Description            string   `json:"description,omitempty"`
	MaxHitsPerQuery        int      `json:"maxHitsPerQuery,omitempty"`
	MaxQueriesPerIPPerHour int      `json:"maxQueriesPerIPPerHour,omitempty"`
	QueryParamaters        string   `json:"queryParameters,omitempty"`
	Referers               []string `json:"referers,omitempty"`
	Validity               int      `json:"validity,omitempty"`
	Value                  string   `json:"value,omitempty"`
}

type listKeysRes struct {
	Keys []Key `json:"keys"`
}

type AddKeyRes struct {
	CreatedAt string `json:"createdAt"`
	Key       string `json:"key"`
}

type UpdateKeyRes struct {
	Key       string `json:"key"`
	UpdatedAt string `json:"updatedAt"`
}
