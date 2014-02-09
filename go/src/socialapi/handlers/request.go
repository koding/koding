package handlers

type Request struct {
	ID    string      `json:"id"`
	Stuff interface{} `json:"stuff"`
}
