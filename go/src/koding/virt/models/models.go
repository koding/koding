package models

import (
	"labix.org/v2/mgo/bson"
	"net"
)

type User struct {
	ObjectId bson.ObjectId `bson:"_id"`
	Uid      int           `bson:"uid"`
	Name     string        `bson:"username"`
	OldName  string        `bson:"oldUsername"`
	Password string        `bson:"password"`
	Salt     string        `bson:"salt"`
	Shell    string        `bson:"shell"`
	SshKeys  []struct {
		Title string `bson:"title"`
		Key   string `bson:"key"`
	} `bson:"sshKeys"`
}

type VM struct {
	Id            bson.ObjectId `bson:"_id"`
	HostnameAlias string        `bson:"hostnameAlias"`
	WebHome       string        `bson:"webHome"`
	Users         []Permissions `bson:"users"`
	LdapPassword  string        `bson:"ldapPassword"`
	NumCPUs       int           `bson:"numCPUs"`
	MaxMemoryInMB int           `bson:"maxMemoryInMB"`
	DiskSizeInMB  int           `bson:"diskSizeInMB"`
	AlwaysOn      bool          `bson:"alwaysOn"`
	SnapshotVM    bson.ObjectId `bson:"diskSnapshot"`
	SnapshotName  string        `bson:"snapshotName"`
	IP            net.IP        `bson:"ip"`
	Region        string        `bson:"region"`
	HostKite      string        `bson:"hostKite"`
	VMRoot        string        `bson:"-"`
}

type Permissions struct {
	Id   bson.ObjectId `bson:"id"`
	Sudo bool          `bson:"sudo"`
}
