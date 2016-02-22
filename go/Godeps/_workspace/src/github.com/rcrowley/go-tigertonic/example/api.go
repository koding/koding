package main

type MyRequest struct {
	ID    string      `json:"id"`
	Stuff interface{} `json:"stuff"`
}

type MyResponse struct {
	ID    string      `json:"id"`
	Stuff interface{} `json:"stuff"`
}
