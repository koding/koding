package handlers

type Response struct {
	ID    string      `json:"id"`
	Stuff interface{} `json:"stuff"`
}
