package koding

import (
	"errors"
	"fmt"
	"koding/kites/kloud/protocol"
	"strings"

	"github.com/dchest/validator"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/route53"
)

var ErrNoRecord = errors.New("no records available")

type DNS struct {
	Route53    *route53.Route53
	hostedZone string
	ZoneId     string
	Log        logging.Logger
}

// NewDNSClient initializes a new DNS instance with default Koding credentials
func NewDNSClient(hostedZone string) *DNS {
	dns := route53.New(DefaultKodingAuth, DefaultAWSRegion)

	hostedZones, err := dns.ListHostedZones("", 100)
	if err != nil {
		panic(err)
	}

	var zoneId string
	for _, h := range hostedZones.HostedZones {
		// the "." point is here because hosteded zones are listed as
		// "dev.koding.io." , "koding.io." and so on
		if h.Name == hostedZone+"." {
			zoneId = route53.CleanZoneID(h.ID)
			break
		}
	}

	if zoneId == "" {
		panic(fmt.Sprintf("Hosted zone with the name '%s' doesn't exist", hostedZone))
	}

	return &DNS{
		Route53:    dns,
		hostedZone: hostedZone,
		ZoneId:     zoneId,
		Log:        logging.NewLogger("kloud-dns"),
	}
}

// Rename changes the domain from oldDomain to newDomain in a single transaction
func (d *DNS) Rename(oldDomain, newDomain, currentIP string) error {
	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Renaming domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "DELETE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    oldDomain,
					TTL:     300,
					Records: []string{currentIP},
				},
			},
			route53.Change{
				Action: "CREATE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    newDomain,
					TTL:     300,
					Records: []string{currentIP},
				},
			},
		},
	}

	d.Log.Info("updating name of IP %s from %v to %v", currentIP, oldDomain, newDomain)
	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

// Update changes the domains ip from oldIP to newIP in a single transaction
func (d *DNS) Update(domain, oldIP, newIP string) error {
	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Updating a domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "DELETE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     300,
					Records: []string{oldIP}, // needs old ip
				},
			},
			route53.Change{
				Action: "CREATE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     300,
					Records: []string{newIP},
				},
			},
		},
	}

	d.Log.Info("updating domain %s IP from %v to %v", domain, oldIP, newIP)
	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

// DeleteDomain deletes a domain record for the given domain with the given ip
// address.
func (d *DNS) Delete(domain string, oldIp string) error {
	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Deleting domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "DELETE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     300,
					Records: []string{oldIp}, // needs old ip
				},
			},
		},
	}

	d.Log.Info("deleting domain name: %s which was associated to following ip: %v", domain, oldIp)
	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

// CreateDomain creates a new domain record for the given domain with the given
// ip address.
func (d *DNS) Create(domain string, newIp string) error {
	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Creating domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "CREATE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     300,
					Records: []string{newIp},
				},
			},
		},
	}

	d.Log.Info("creating domain name: %s to be associated with following ip: %v", domain, newIp)
	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

// Domain retrieves the record set for the given domain name
func (d *DNS) Get(domain string) (*protocol.Record, error) {
	lopts := &route53.ListOpts{
		Name: domain,
	}

	d.Log.Info("fetching domain record for name: %s", domain)

	resp, err := d.Route53.ListResourceRecordSets(d.ZoneId, lopts)
	if err != nil {
		return nil, err
	}

	if len(resp.Records) == 0 {
		return nil, ErrNoRecord
	}

	for _, r := range resp.Records {
		if strings.Contains(r.Name, domain) {
			return &protocol.Record{
				Name: r.Name,
				IP:   r.Records[0],
				TTL:  r.TTL,
			}, nil
		}
	}

	return nil, ErrNoRecord
}

func (d *DNS) HostedZone() string {
	return d.hostedZone
}

func (d *DNS) Validate(domain, username string) error {
	hostedZone := d.hostedZone

	f := strings.TrimSuffix(domain, "."+username+"."+hostedZone)
	if f == domain {
		return fmt.Errorf("Domain is invalid (1) '%s'", domain)
	}

	if !strings.Contains(domain, username) {
		return fmt.Errorf("Domain doesn't contain username '%s'", username)
	}

	if !strings.Contains(domain, hostedZone) {
		return fmt.Errorf("Domain doesn't contain hostedzone '%s'", hostedZone)
	}

	if !validator.IsValidDomain(domain) {
		return fmt.Errorf("Domain is invalid (2) '%s'", domain)
	}

	return nil
}
