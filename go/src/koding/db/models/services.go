package models

import "labix.org/v2/mgo/bson"

type KeyData struct {
	// Versioning of hosts
	Key string `json:"key"`

	// List of hosts to proxy
	Host []string `json:"host"`

	// LoadBalance for this server
	LoadBalancer LoadBalancer `json:"loadBalancer"`

	// future usage...
	HostData string `json:"hostData"`

	// future usage, proxy via mq
	RabbitKey string `json:"rabbitKey"`
}

type KeyRoutingTable struct {
	Keys map[string]KeyData `json:"keys"`
}

type Service struct {
	Id       bson.ObjectId              `bson:"_id" json:"-"`
	Username string                     `bson:"username" json:"username"`
	Services map[string]KeyRoutingTable `bson:"services" json:"services"`
}
