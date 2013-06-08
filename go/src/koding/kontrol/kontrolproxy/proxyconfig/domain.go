package proxyconfig

import (
	"labix.org/v2/mgo/bson"
)

type Domain struct {
	// Id defines the ObjectId of a single mongo document.
	Id bson.ObjectId `bson:"_id" json:"-"`

	// Domainname is the host name without any protocol scheme (i.e "new.koding.com")
	Domainname string `bson:"domainname" json:"domainname"`

	// Mode defines how proxy should act on domains. There are currently three
	// modes used which defines the way the domain is proxied. These are:
	// internal : to point name-key.in.koding.com
	// direct   : to point fullurl
	// vm       : to point username.kd.io
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

	// FullUrl is used with mode "direct". Proxy will directly proxy to this
	// given fullurl. It should be in HOST form, means no scheme should be
	// used. Example: www.google.com, arslan.io, koding.com
	FullUrl string `bson:"fullurl" json:"fullurl,omitempty"`
}

// NewDomain returns a new Domain using the provided arguments. A new unique
// ObjectId is created automatically whenever a new Domain is created.
func NewDomain(domainname, mode, username, servicename, key, fullurl string) *Domain {
	return &Domain{
		Id:          bson.NewObjectId(),
		Domainname:  domainname,
		Mode:        mode,
		Username:    username,
		Servicename: servicename,
		Key:         key,
		FullUrl:     fullurl,
	}
}

// AddDomain adds or updates a new domain document. If "domainname" is
// available it updates the old document with the new arguments (except
// domainname). If not available it adds a new document with the given
// arguments.
func (p *ProxyConfiguration) AddDomain(domainname, mode, username, servicename, key, fullurl string) error {
	domain := *NewDomain(domainname, mode, username, servicename, key, fullurl)
	_, err := p.Collection["domains"].Upsert(bson.M{"domainname": domainname}, domain)
	if err != nil {
		return err
	}
	return nil
}

// DeleteDomain deletes the document with the given "domainname" argument.
func (p *ProxyConfiguration) DeleteDomain(domainname string) error {
	err := p.Collection["domains"].Remove(bson.M{"domainname": domainname})
	if err != nil {
		return err
	}
	return nil
}

// GetDomain return a single document that match the given "domainname"
// argument.
func (p *ProxyConfiguration) GetDomain(domainname string) (Domain, error) {
	domain := Domain{}
	err := p.Collection["domains"].Find(bson.M{"domainname": domainname}).One(&domain)
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
