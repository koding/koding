package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type WorkerStatus int

const (
	Started WorkerStatus = iota
	Killed
	Dead
	Waiting
)

type Worker struct {
	ObjectId           bson.ObjectId `bson:"_id"`
	Name               string        `bson:"name" json:"name"`
	ServiceGenericName string        `bson:"serviceGenericName" json:"serviceGenericName"`
	ServiceUniqueName  string        `bson:"serviceUniqueName" json:"serviceUniqueName"`
	Uuid               string        `bson:"uuid" json:"uuid"`
	Hostname           string        `bson:"hostname" json:"hostname"`
	Version            int           `bson:"version" json:"version"`
	Timestamp          time.Time     `bson:"timestamp" json:"timestamp"`
	Pid                int           `bson:"pid" json:"pid"`
	ProxyName          string        `bson:"proxyName", json:"proxyName"`
	Status             WorkerStatus  `bson:"status" json:"status"`
	Environment        string        `bson:"environment" json:"environment"`
	Number             int           `bson:"number" json:"number"`
	Message            struct {
		Command string `bson:"command" json:"command"`
		Option  string `bson:"option" json:"option"`
	} `bson:"message" json:"message"`
	Port    int `bson:"port" json:"port"`
	Monitor struct {
		Mem    MemData `bson:"json" json:"mem"`
		Uptime int     `bson:"uptime" json:"uptime"`
	} `bson:"monitor" json:"monitor"`
}

type MemData struct {
	Rss       int    `bson:"rss" json:"rss"`
	HeapTotal int    `bson:"heaptotal" json:"heaptotal"`
	HeapUsed  int    `bson:"heapused" json:"heapused"`
	Unit      string `bson:"unit" json:"unit"`
}

type Monitor struct {
	ObjectId bson.ObjectId `bson:"_id"`
	Name     string        `bson:"monitor"`
	Uuid     string        `bson:"uuid"`
	Mem      *MemData      `bson:"mem"`
	Uptime   int           `bson:"uptime"`
}
