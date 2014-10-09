package koding

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/protocol"
	"time"

	"github.com/koding/logging"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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

type Domains struct {
	DB  *mongodb.MongoDB
	Log logging.Logger
}

func NewDomainStorage(db *mongodb.MongoDB) *Domains {
	return &Domains{
		DB:  db,
		Log: logging.NewLogger("kloud-domain"),
	}
}

func (d *Domains) Add(domain *protocol.Domain) error {
	var account *models.Account
	if err := d.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": domain.Username}).One(&account)
	}); err != nil {
		d.Log.Error("Could not fetch account %v: err: %v", domain.Username, err)
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

	err := d.DB.Run("jDomainAlias", func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"domain": domain.Name}, doc)
		return err
	})

	if err != nil {
		d.Log.Error("Could not add %v: err: %v", doc, err)
		return errors.New("could not add account from DB")
	}

	return nil

}

func (d *Domains) Delete(name string) error {
	err := d.DB.Run("jDomainAlias", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"domain": name})
	})

	if err != nil {
		d.Log.Error("Could not delete %v: err: %v", name, err)
		return errors.New("could not delete domain from DB")
	}

	return nil
}

func (d *Domains) Get(name string) (*protocol.Domain, error) {
	doc := &DomainDocument{}
	err := d.DB.Run("jDomainAlias", func(c *mgo.Collection) error {
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

func (d *Domains) UpdateMachine(name, machineId string) error {
	err := d.DB.Run("jDomainAlias", func(c *mgo.Collection) error {
		return c.Update(bson.M{"domain": name},
			bson.M{"$set": bson.M{
				"machineId":  machineId,
				"modifiedAt": time.Now().UTC(),
			}})
	})

	if err != nil {
		d.Log.Error("Could not update %v: err: %v", name, err)
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
