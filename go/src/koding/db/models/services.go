package models

import "labix.org/v2/mgo/bson"

type KeyData struct {
	// Versioning of hosts
	Key string `json:"key"`

	// List of hosts to proxy
	Host []string `json:"host"`

	// Contains additional data about the hosts, like region information
	HostData string `json:"hostData"`

	// If true proxy is allowd to route to the given hosts.
	Enabled bool `json:"enabled"`
}

type KeyRoutingTable struct {
	Keys map[string]KeyData `json:"keys"`
}

type Service struct {
	Id       bson.ObjectId              `bson:"_id" json:"-"`
	Username string                     `bson:"username" json:"username"`
	Services map[string]KeyRoutingTable `bson:"services" json:"services"`
}
