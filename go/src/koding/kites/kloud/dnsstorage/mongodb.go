// Package dnsstorage is used to
package dnsstorage

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"time"

	"github.com/koding/logging"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
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

type MongodbStorage struct {
	DB  *mongodb.MongoDB
	Log logging.Logger
}

func NewMongodbStorage(db *mongodb.MongoDB) *MongodbStorage {
	return &MongodbStorage{
		DB:  db,
		Log: logging.NewLogger("kloud-domain"),
	}
}

func (m *MongodbStorage) Add(domain *Domain) error {
	var account *models.Account
	if err := m.DB.Run("jAccounts", func(c *mgo.Collection) error {
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

	err := m.DB.Run(domainCollection, func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"domain": domain.Name}, doc)
		return err
	})

	if err != nil {
		m.Log.Error("Could not add %v: err: %v", doc, err)
		return errors.New("could not add account from DB")
	}

	return nil
}

func (m *MongodbStorage) Delete(name string) error {
	err := m.DB.Run(domainCollection, func(c *mgo.Collection) error {
		return c.Remove(bson.M{"domain": name})
	})

	if err != nil {
		m.Log.Error("Could not delete %v: err: %v", name, err)
		return errors.New("could not delete domain from DB")
	}

	return nil
}

func (m *MongodbStorage) Get(name string) (*Domain, error) {
	doc := &DomainDocument{}
	err := m.DB.Run(domainCollection, func(c *mgo.Collection) error {
		return c.Find(bson.M{"domain": name}).One(&doc)
	})
	if err != nil {
		return nil, err
	}

	return &Domain{
		MachineId: doc.MachineId.Hex(),
		Name:      doc.DomainName,
	}, nil
}

func (m *MongodbStorage) GetByMachine(machineId string) ([]*Domain, error) {
	domainDocuments := make([]DomainDocument, 0)

	query := func(c *mgo.Collection) error {
		domain := DomainDocument{}

		iter := c.Find(bson.M{"machineId": bson.ObjectIdHex(machineId)}).Batch(20).Iter()
		for iter.Next(&domain) {
			domainDocuments = append(domainDocuments, domain)
		}

		return iter.Close()
	}

	if err := m.DB.Run(domainCollection, query); err != nil {
		return nil, err
	}

	domains := make([]*Domain, len(domainDocuments))

	for i, domain := range domainDocuments {
		domains[i] = &Domain{
			Username:  domain.OriginId.Hex(),
			MachineId: machineId,
			Name:      domain.DomainName,
		}
	}

	return domains, nil
}

func (m *MongodbStorage) UpdateMachine(name, machineId string) error {
	updateData := bson.M{
		"machineId":  "",
		"modifiedAt": time.Now().UTC(),
	}

	if machineId != "" {
		if !bson.IsObjectIdHex(machineId) {
			return fmt.Errorf("%q is not a valid object Id", machineId)
		}

		updateData["machineId"] = bson.ObjectIdHex(machineId)
	}

	err := m.DB.Run(domainCollection, func(c *mgo.Collection) error {
		return c.Update(bson.M{"domain": name},
			bson.M{"$set": updateData},
		)
	})

	if err != nil {
		m.Log.Error("Could not update %v: err: %v", name, err)
		return errors.New("could not update domain from DB")
	}

	return nil
}
