package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

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

	// CacheEnabled is used to enable caching for HTTP requests. It only
	// caches the files that ends with the suffixes defined in
	// CacheSuffixes field"
	CacheEnabled bool `bson:"cacheEnabled" json:"fullUrl,omitempty"`

	// CacheSuffixes is a comma delimited string that defines which files
	// are going to be cached. An example value might be: "jpg,ttf,js,css"
	CacheSuffixes string `bson:"cacheSuffixes" json:"cacheSuffixes,omitempty"`
}

type LoadBalancer struct {
	// cookie or sourceAddress
	Persistence string `json:"persistence"`

	// roundrobin or random
	Mode string `json:"mode"`
}
