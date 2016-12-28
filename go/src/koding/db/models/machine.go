package models

import (
	"koding/kites/kloud/machinestate"
	"time"

	"gopkg.in/mgo.v2/bson"
)

type MachineGroup struct {
	Id bson.ObjectId `bson:"id" json:"id"`
}

type MachineStatus struct {
	State      string    `bson:"state" json:"state"`
	Reason     string    `bons:"reason" json:"reason"`
	ModifiedAt time.Time `bson:"modifiedAt" json:"modifiedAt"`
}

type MachineUser struct {
	Id        bson.ObjectId `bson:"id" json:"id"`
	Sudo      bool          `bson:"sudo" json:"sudo"`
	Owner     bool          `bson:"owner" json:"owner"`
	Permanent bool          `bson:"permanent" json:"permanent"`
	Approved  bool          `bson:"approved" json:"approved"`
	Username  string        `bson:"username" json:"username"`
}

type MachineAssignee struct {
	AssignedAt      time.Time `bson:"assignedAt" json:"assignedAt"`
	InProgress      bool      `bson:"inProgress" json:"inProgress"`
	KlientMissingAt time.Time `bson:"klientMissingAt,omitempty" json:"klientMissingAt,omitempty"`
}

type MachineGeneratedFrom struct {
	TemplateId bson.ObjectId `bson:"templateId" json:"templateId"`
	Revision   string        `bson:"revision" json:"revision"`
}

type Machine struct {
	ObjectId      bson.ObjectId         `bson:"_id" json:"_id"`
	Uid           string                `bson:"uid" json:"uid"`
	QueryString   string                `bson:"queryString,omitempty" json:"queryString"`
	IpAddress     string                `bson:"ipAddress" json:"ipAddress"`
	RegisterURL   string                `bson:"registerUrl" json:"registerUrl"`
	Domain        string                `bson:"domain" json:"domain"`
	Provider      string                `bson:"provider" json:"provider"`
	Label         string                `bson:"label" json:"label"`
	Slug          string                `bson:"slug" json:"slug"`
	Provisoners   []bson.ObjectId       `bson:"provisoners" json:"provisoners"`
	Credential    string                `bson:"credential" json:"credential"`
	Users         []MachineUser         `bson:"users" json:"users"`
	Groups        []MachineGroup        `bson:"groups" json:"groups"`
	CreatedAt     time.Time             `bson:"createdAt" json:"createdAt" `
	Status        MachineStatus         `bson:"status" json:"status"`
	Meta          bson.M                `bson:"meta" json:"meta"`
	Assignee      MachineAssignee       `bson:"assignee" json:"assignee"`
	UserDeleted   bool                  `bson:"userDeleted" json:"userDeleted"`
	GeneratedFrom *MachineGeneratedFrom `bson:"generatedFrom,omitempty" json:"generatedFrom,omitempty"`
}

// Owner returns the owner of a machine
func (m *Machine) Owner() *MachineUser {
	for _, user := range m.Users {
		// this is the correct way to remove all users but the owner from a
		// machine
		if user.Sudo && user.Owner {
			return &user
		}
	}

	return nil
}

// State returns the machinestate of the machine
func (m *Machine) State() machinestate.State {
	return machinestate.States[m.Status.State]
}
