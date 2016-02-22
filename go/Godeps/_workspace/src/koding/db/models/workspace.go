package models

import "gopkg.in/mgo.v2/bson"

type Workspace struct {
	ObjectId     bson.ObjectId `bson:"_id" json:"_id"`
	OriginId     bson.ObjectId `bson:"originId" json:"originId"`
	Name         string        `bson:"name" json:"name"`
	Slug         string        `bson:"slug" json:"slug"`
	ChannelId    string        `bson:"channelId" json:"channelId"`
	MachineUID   string        `bson:"machineUId" json:"machineUId"`
	MachineLabel string        `bson:"machineLabel" json:"machineLabel"`
	Owner        string        `bson:"owner" json:"owner"`
	RootPath     string        `bson:"rootPath" json:"rootPath"`
	IsDefault    bool          `bson:"isDefault" json:"isDefault"`
	Layout       interface{}   `bson:"layout" json:"layout"`
}
