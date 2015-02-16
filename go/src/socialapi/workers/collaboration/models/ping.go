package models

type Ping struct {
	FileId    string `json:"fileId"`
	AccountId int64  `json:"accountId,string"`
}
