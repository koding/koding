package models

import (
	"net"

	"labix.org/v2/mgo/bson"
)

type VM struct {
	Id                bson.ObjectId `bson:"_id"`
	HostnameAlias     string        `bson:"hostnameAlias"`
	WebHome           string        `bson:"webHome"`
	Users             []Permissions `bson:"users"`
	Groups            []Permissions `bson:"groups"`
	LdapPassword      string        `bson:"ldapPassword"`
	NumCPUs           int           `bson:"numCPUs"`
	MaxMemoryInMB     int           `bson:"maxMemoryInMB"`
	DiskSizeInMB      int           `bson:"diskSizeInMB"`
	AlwaysOn          bool          `bson:"alwaysOn"`
	DisableSecurePage bool          `bson:"disableSecurePage"`
	PinnedToHost      string        `bson:"pinnedToHost"`
	SnapshotVM        bson.ObjectId `bson:"diskSnapshot"`
	SnapshotName      string        `bson:"snapshotName"`
	IP                net.IP        `bson:"ip"`
	Region            string        `bson:"region"`
	HostKite          string        `bson:"hostKite"`
	VMRoot            string        `bson:"vmRoot"`
}

type Permissions struct {
	Id    bson.ObjectId `bson:"id"`
	Sudo  bool          `bson:"sudo"`
	Owner bool          `bson:"owner"`
}
