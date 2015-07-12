package services

import "net/http"

type Iterable struct {
	EventName  string
	DataFields map[string]interface{}
	CampaignId string
	Username   string
	Message    string
	GroupName  string
}

func NewIterable() (Iterable, error) {
	return Iterable{}, nil
}

func (i Iterable) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	w.WriteHeader(http.StatusNoContent)
}

func (i Iterable) Configure(req *http.Request) (interface{}, error) {
	return nil, nil
}
