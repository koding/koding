package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type DomainStat struct {
	Id           bson.ObjectId  `bson:"_id" json:"-"`
	Domainname   string         `bson:"domainname" json:"domainname"`
	RequestsHour map[string]int `bson:"requesthour" json:"requesthour"`
	Denied       []DomainDenied
}

type ProxyStat struct {
	Id           bson.ObjectId  `bson:"_id" json:"-"`
	Proxyname    string         `bson:"proxyname" json:"proxyname"`
	Country      map[string]int `bson:"country" json:"country"`
	RequestsHour map[string]int `bson:"requesthour" json:"requesthour"`
}

type DomainDenied struct {
	IP       string
	Country  string
	Reason   string
	DeniedAt time.Time
}
