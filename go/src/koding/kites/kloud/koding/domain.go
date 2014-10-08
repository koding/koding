package koding

import (
	"errors"
	"koding/db/mongodb"
	"koding/kites/kloud/protocol"
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

type Domains struct {
	DB *mongodb.MongoDB
}

func NewDomainStorage(db *mongodb.MongoDB) *Domains {
	return &Domains{
		DB: db,
	}
}

func (d *Domains) Add(domain *protocol.Domain) error {
	return errors.New("not implemented yet.")
}

func (d *Domains) Delete(id string) error {
	return errors.New("not implemented yet.")
}

func (d *Domains) Get(id string) (*protocol.Domain, error) {
	return nil, errors.New("not implemented yet.")
}

// UpdateDomain sets the ip to the given domain. If there is no record a new
// record will be created otherwise existing record is updated. This is just a
// helper method that uses our DNS struct.
func (p *Provider) UpdateDomain(ip, domain, username string) error {
	if err := p.DNS.Validate(domain, username); err != nil {
		return err
	}

	// Check if the record exist, if yes update the ip instead of creating a new one.
	record, err := p.DNS.Get(domain)
	if err == ErrNoRecord {
		if err := p.DNS.Create(domain, ip); err != nil {
			return err
		}
	} else if err != nil {
		// If it's something else just return it
		return err
	}

	// Means the record exist, update it
	if err == nil {
		p.Log.Warning("Domain '%s' already exists (that shouldn't happen). Going to update to new IP", domain)
		if err := p.DNS.Update(domain, record.IP, ip); err != nil {
			return err
		}
	}

	return nil
}
