package koding

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/protocol"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	domainCollection = "jDomainAliases"
)

// DomainDocument defines a single MongoDB document in the jDomains collection
type DomainDocument struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	OriginId   bson.ObjectId `bson:"originId"`
	MachineId  bson.ObjectId `bson:"machineId"`
	DomainName string        `bson:"domain"`
	CreatedAt  time.Time     `bson:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt"`
}

func (m *Machine) AddDomain(domain *protocol.Domain) error {
	var account *models.Account
	if err := m.Session.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": domain.Username}).One(&account)
	}); err != nil {
		m.Log.Error("Could not fetch account %v: err: %v", domain.Username, err)
		return errors.New("could not fetch account from DB")
	}

	doc := &DomainDocument{
		Id:         bson.NewObjectId(),
		OriginId:   account.Id,
		MachineId:  bson.ObjectIdHex(domain.MachineId),
		DomainName: domain.Name,
		CreatedAt:  time.Now().UTC(),
		ModifiedAt: time.Now().UTC(),
	}

	err := m.Session.DB.Run(domainCollection, func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"domain": domain.Name}, doc)
		return err
	})

	if err != nil {
		m.Log.Error("Could not add %v: err: %v", doc, err)
		return errors.New("could not add account from DB")
	}

	return nil
}

func (m *Machine) DeleteDomain(name string) error {
	err := m.Session.DB.Run(domainCollection, func(c *mgo.Collection) error {
		return c.Remove(bson.M{"domain": name})
	})

	if err != nil {
		m.Log.Error("Could not delete %v: err: %v", name, err)
		return errors.New("could not delete domain from DB")
	}

	return nil
}

func (m *Machine) DomainByName(name string) (*protocol.Domain, error) {
	doc := &DomainDocument{}
	err := m.Session.DB.Run(domainCollection, func(c *mgo.Collection) error {
		return c.Find(bson.M{"domain": name}).One(&doc)
	})
	if err != nil {
		return nil, err
	}

	return &protocol.Domain{
		MachineId: doc.MachineId.Hex(),
		Name:      doc.DomainName,
	}, nil
}

func (m *Machine) DomainsById() ([]*protocol.Domain, error) {
	domainDocuments := make([]DomainDocument, 0)

	query := func(c *mgo.Collection) error {
		domain := DomainDocument{}

		iter := c.Find(bson.M{"machineId": m.Id}).Batch(20).Iter()
		for iter.Next(&domain) {
			domainDocuments = append(domainDocuments, domain)
		}

		return iter.Close()
	}

	if err := m.Session.DB.Run(domainCollection, query); err != nil {
		return nil, err
	}

	domains := make([]*protocol.Domain, len(domainDocuments))

	for i, domain := range domainDocuments {
		domains[i] = &protocol.Domain{
			Username:  domain.OriginId.Hex(),
			MachineId: m.Id.Hex(),
			Name:      domain.DomainName,
		}
	}

	return domains, nil
}

func (m *Machine) UpdateDomain(domainName, machineId string) error {
	updateData := bson.M{
		"machineId":  "",
		"modifiedAt": time.Now().UTC(),
	}

	if machineId != "" {
		if !bson.IsObjectIdHex(machineId) {
			return fmt.Errorf("'%s' is not a valid object Id", machineId)
		}

		updateData["machineId"] = bson.ObjectIdHex(machineId)
	}

	err := m.Session.DB.Run(domainCollection, func(c *mgo.Collection) error {
		return c.Update(
			bson.M{"domain": domainName},
			bson.M{"$set": updateData},
		)
	})

	if err != nil {
		m.Log.Error("Could not update %v: err: %v", domainName, err)
		return errors.New("could not update domain from DB")
	}

	return nil
}

// UpdateDomain sets the ip to the given domain. If there is no record a new
// record will be created otherwise existing record is updated. This is just a
// helper method that uses our DNS struct.
func (p *Provider) UpdateDomain(ip, domain, username string) error {
	if err := p.DNS.Validate(domain, username); err != nil {
		return err
	}

	return p.DNS.Upsert(domain, ip)
}
