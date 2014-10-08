package koding

import (
	"errors"
	"fmt"
	"strings"

	"github.com/koding/logging"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/route53"
)

var ErrNoRecord = errors.New("no records available")

type DNS struct {
	Route53 *route53.Route53
	ZoneId  string
	Log     logging.Logger
}

func (p *Provider) InitDNS(accessKey, secretKey string) error {
	p.Log.Info("DNS middleware is not initialized. Initializing...")
	dns := route53.New(
		aws.Auth{
			AccessKey: accessKey,
			SecretKey: secretKey,
		},
		aws.Regions[DefaultRegion],
	)

	p.Log.Info("Searching for hosted zone: %s", p.HostedZone)
	hostedZones, err := dns.ListHostedZones("", 100)
	if err != nil {
		return err
	}

	var zoneId string
	for _, h := range hostedZones.HostedZones {
		// the "." point is here because hosteded zones are listed as
		// "dev.koding.io." , "koding.io." and so on
		if h.Name == p.HostedZone+"." {
			zoneId = route53.CleanZoneID(h.ID)
			break
		}
	}

	if zoneId == "" {
		return fmt.Errorf("Hosted zone with the name '%s' doesn't exist", p.HostedZone)
	}

	p.DNS = &DNS{
		Route53: dns,
		ZoneId:  zoneId,
		Log:     p.Log,
	}

	return nil
}

// Rename changes the domain from oldDomain to newDomain in a single transaction
func (d *DNS) Rename(oldDomain, newDomain string, currentIP string) error {
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
func (d *DNS) Update(domain string, oldIP, newIP string) error {
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
// addresses.
func (d *DNS) DeleteDomain(domain string, ips ...string) error {
	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Deleting domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "DELETE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     300,
					Records: ips, // needs old ip
				},
			},
		},
	}

	d.Log.Info("deleting domain name: %s which was associated to following ips: %v", domain, ips)
	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

// CreateDomain creates a new domain record for the given domain with the given
// ip addresses.
func (d *DNS) CreateDomain(domain string, ips ...string) error {
	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Creating domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "CREATE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     300,
					Records: ips,
				},
			},
		},
	}

	d.Log.Info("creating domain name: %s to be associated with following ips: %v", domain, ips)
	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

// Domain retrieves the record set for the given domain name
func (d *DNS) Domain(domain string) (route53.ResourceRecordSet, error) {
	lopts := &route53.ListOpts{
		Name: domain,
	}

	d.Log.Info("fetching domain record for name: %s", domain)

	resp, err := d.Route53.ListResourceRecordSets(d.ZoneId, lopts)
	if err != nil {
		return route53.ResourceRecordSet{}, err
	}

	if len(resp.Records) == 0 {
		return route53.ResourceRecordSet{}, ErrNoRecord
	}

	for _, r := range resp.Records {
		if strings.Contains(r.Name, domain) {
			return r, nil
		}

	}

	return route53.ResourceRecordSet{}, ErrNoRecord
}
