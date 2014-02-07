package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewRelationship() *models.Relationship {
	return &models.Relationship{
		Id: bson.NewObjectId(),
	}
}

// NewProxyTable returns a new Domain using the provided arguments. A new unique
// ObjectId is created automatically whenever a new Domain is created.
func NewProxyTable(mode, username, servicename, key, fullurl string) *models.ProxyTable {
	return &models.ProxyTable{
		Mode:        mode,
		Username:    username,
		Servicename: servicename,
		Key:         key,
		FullUrl:     fullurl,
	}
}

// NewDomain returns a new Domain using the provided arguments. A new unique
// ObjectId is created automatically whenever a new Domain is created.
func NewDomain(domainname, mode, username, servicename, key, fullurl string, hostnames []string) *models.Domain {
	return &models.Domain{
		Id:            bson.NewObjectId(),
		Domain:        domainname,
		HostnameAlias: hostnames,
		Proxy:         NewProxyTable(mode, username, servicename, key, fullurl),
	}
}

// AddDomain adds or updates a new domain document. If "domainname" is
// available it updates the old document with the new arguments (except
// domainname). If not available it adds a new document with the given
// arguments.
func AddDomain(d *models.Domain) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"domain": d.Domain}, d)
		if err != nil {
			fmt.Println("AddDomain error", err)
			return fmt.Errorf("domain %s exists already", d.Domain)
		}
		return nil
	}

	return Mongo.Run("jDomains", query)
}

// UpdateDomain updates an already avalaible domain document. If not available
// it returns an error
func UpdateDomain(d *models.Domain) error {
	domain, err := GetDomain(d.Domain)
	if err != nil {
		if err == mgo.ErrNotFound {
			return fmt.Errorf("domain %s does not exist", d.Domain)
		}
		return err
	}

	hostnames := domain.HostnameAlias

	hasHostname := false
	for _, hostname := range hostnames {
		if hostname == d.HostnameAlias[0] {
			hasHostname = true // don't append an already added host
			break
		}
	}

	if !hasHostname {
		domain.HostnameAlias = append(domain.HostnameAlias, d.HostnameAlias[0])
	}

	domain.Proxy = d.Proxy
	domain.LoadBalancer.Mode = d.LoadBalancer.Mode

	query := func(c *mgo.Collection) error {
		err = c.Update(bson.M{"domain": d.Domain}, domain)
		if err != nil {
			if err == mgo.ErrNotFound {
				return fmt.Errorf("domain %s does not exist.", d.Domain)
			}
			return err
		}
		return nil
	}

	return Mongo.Run("jDomains", query)
}

// DeleteDomain deletes the document with the given "domainname" argument.
func DeleteDomain(domainname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"domain": domainname})
	}

	return Mongo.Run("jDomains", query)
}

// GetDomain return a single document that match the given "domainname"
// argument.
func GetDomain(domainname string) (*models.Domain, error) {
	domain := new(models.Domain)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"domain": domainname}).One(&domain)
	}

	err := Mongo.Run("jDomains", query)
	if err != nil {
		return domain, err
	}

	return domain, nil
}

// GetDomains returns an array of Domain struct of all available domains.
func GetDomains() []models.Domain {
	domain := models.Domain{}
	domains := make([]models.Domain, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&domain) {
			domains = append(domains, domain)
		}

		return nil
	}

	Mongo.Run("jDomains", query)

	return domains
}

func GetDomainRestrictionId(sourceId bson.ObjectId) (bson.ObjectId, error) {
	relationship := models.Relationship{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"sourceID": sourceId, "targetName": "JProxyRestrictions"}).One(&relationship)
	}

	err := Mongo.Run("relationships", query)
	if err != nil {
		return "", err
	}

	return relationship.Id, nil
}
