package koding

import (
	"errors"
	"koding/db/mongodb"
	"time"

	"labix.org/v2/mgo/bson"
)

// DomainDocument defines a single MongoDB document in the jDomains collection
type DomainDocument struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	MachineId  bson.ObjectId `bson:"machineId"`
	DomainName string        `bson:"domainName"`
	CreatedAt  time.Time     `bson:"createdAt"`
}

type DomainStorage interface {
	// Add adds a new DomainDocument
	Add(*DomainDocument) error

	// Delete deletes the DomainDocument with the given domain name
	Delete(name string) error

	// Get returns the DomainDocument with the given domain name
	Get(name string) (*DomainDocument, error)
}

type Domains struct {
	DB *mongodb.MongoDB
}

func NewDomainStorage(db *mongodb.MongoDB) DomainStorage {
	return &Domains{
		DB: db,
	}
}

func (d *Domains) Add(domain *DomainDocument) error {
	return errors.New("not implemented yet.")
}

func (d *Domains) Delete(id string) error {
	return errors.New("not implemented yet.")
}

func (d *Domains) Get(id string) (*DomainDocument, error) {
	return nil, errors.New("not implemented yet.")
}
