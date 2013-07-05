package proxyconfig

import (
	"fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"time"
)

type Relationship struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	TargetId   bson.ObjectId `bson:"targetId"`
	TargetName string        `bson:"targetName"`
	SourceId   bson.ObjectId `bson:"sourceId"`
	SourceName string        `bson:"sourceName"`
	As         string        `bson:"as"`
	TimeStamp  time.Time     `bson:"timestamp"`
}

func NewRelationship() *Relationship {
	return &Relationship{
		Id: bson.NewObjectId(),
	}
}

type LoadBalancer struct {
	// cookie or sourceAddress
	Persistence string `json:"persistence"`

	// roundrobin or random
	Mode string `json:"mode"`
}

type Domain struct {
	// Id defines the ObjectId of a single mongo document.
	Id bson.ObjectId `bson:"_id" json:"-"`

	// Domain is the domain in host form without any scheme (i.e: new.koding.com)
	Domain string `bson:"domain"`

	// HostnameAlias is used for proxy to route the domain to their VM defined
	// by the HostnameAlias.
	HostnameAlias []string `bson:"hostnameAlias"`

	// LoadBalance for this server
	LoadBalancer LoadBalancer `bson:"loadBalancer"`

	// ProxyTable is used for proxy to route domains to their specific targets
	Proxy *ProxyTable `bson:"proxy"`

	OrderId struct {
		Recurly       string
		ResellersClub string
	} `bson:"orderId"`

	RegYears int `bson:"regYears"`

	CreatedAt  time.Time `bson:"createdAt"`
	ModifiedAt time.Time `bson:"modifiedAt"`
}

type ProxyTable struct {
	// Mode defines how proxy should act on domains. There are currently three
	// modes used which defines the way the domain is proxied. These are:
	// internal 	: to point name-key.in.koding.com
	// redirect 	: to point fullurl
	// vm       	: to point username.kd.io
	// maintenance	: to show maintenance static page
	Mode string `bson:"mode" json:"mode"`

	// Username is used with mode "vm" or mode "internal".
	// For mode "vm" the domain is proxied to the Username's VM Ip.
	// For mode "internal", the domain is proxied to one of the services of
	// Username
	Username string `bson:"username" json:"username,omitempty"`

	// Servicename is used with mode "internal". This is needed for domainnames
	// in form of {service}-{key}-{username}.in.koding.com. Proxy assumes that
	// domains in form of {service}-{key}.in.koding.com belongs by default to
	// Username "koding". In order to user a Service please don't forget to
	// create a new Service and Key in the RoutingTable. This can be done with
	// the services.go package
	Servicename string `bson:"servicename,omitempty" json:"servicename,omitempty"`

	// Same as Servicename. Key is also the version number of a service. You
	// can have multiple versions of a service sitting on your server and then
	// whenever you create a new version of your service just update the Key
	// field. Handy if you have multiple servers and you want to jumb between
	// them (like if something goes wrong with your latest version, you can
	// update Key to use the old one)
	Key string `bson:"key" json:"key,omitempty"`

	// FullUrl is used with mode "redirect". Proxy will redirect to this given
	// fullurl. It should be in HOST form, means no scheme should be used.
	// Example: www.google.com, arslan.io, koding.com
	FullUrl string `bson:"fullurl" json:"fullUrl,omitempty"`
}

// NewProxyTable returns a new Domain using the provided arguments. A new unique
// ObjectId is created automatically whenever a new Domain is created.
func NewProxyTable(mode, username, servicename, key, fullurl string) *ProxyTable {
	return &ProxyTable{
		Mode:        mode,
		Username:    username,
		Servicename: servicename,
		Key:         key,
		FullUrl:     fullurl,
	}
}

// NewDomain returns a new Domain using the provided arguments. A new unique
// ObjectId is created automatically whenever a new Domain is created.
func NewDomain(domainname, mode, username, servicename, key, fullurl string, hostnames []string) *Domain {
	return &Domain{
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
func (p *ProxyConfiguration) AddDomain(d *Domain) error {
	_, err := p.Collection["domains"].Upsert(bson.M{"domain": d.Domain}, d)
	if err != nil {
		fmt.Println("AddDomain error", err)
		return fmt.Errorf("domain %s exists already", d.Domain)
	}
	return nil
}

// UpdateDomain updates an already avalaible domain document. If not available
// it returns an error
func (p *ProxyConfiguration) UpdateDomain(d *Domain) error {
	domain, err := p.GetDomain(d.Domain)
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

	err = p.Collection["domains"].Update(bson.M{"domain": d.Domain}, domain)
	if err != nil {
		if err == mgo.ErrNotFound {
			return fmt.Errorf("domain %s does not exist.", d.Domain)
		}
		return err
	}
	return nil
}

// DeleteDomain deletes the document with the given "domainname" argument.
func (p *ProxyConfiguration) DeleteDomain(domainname string) error {
	err := p.Collection["domains"].Remove(bson.M{"domain": domainname})
	if err != nil {
		return err
	}
	return nil
}

// GetDomain return a single document that match the given "domainname"
// argument.
func (p *ProxyConfiguration) GetDomain(domainname string) (Domain, error) {
	domain := Domain{}
	err := p.Collection["domains"].Find(bson.M{"domain": domainname}).One(&domain)
	if err != nil {
		return domain, err
	}
	return domain, nil
}

// GetDomains returns an array of Domain struct of all available domains.
func (p *ProxyConfiguration) GetDomains() []Domain {
	domain := Domain{}
	domains := make([]Domain, 0)
	iter := p.Collection["domains"].Find(nil).Iter()
	for iter.Next(&domain) {
		domains = append(domains, domain)
	}

	return domains
}

func (p *ProxyConfiguration) GetDomainRestrictionId(sourceId bson.ObjectId) (bson.ObjectId, error) {
	relationship := Relationship{}
	err := p.Collection["relationships"].Find(
		bson.M{"sourceID": sourceId, "targetName": "JProxyRestrictions"},
	).One(&relationship)
	if err != nil {
		return "", err
	}

	return relationship.Id, nil
}
