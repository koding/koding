package koding

import (
	"fmt"
	"strings"

	"github.com/dchest/validator"
	"github.com/koding/kloud/protocol"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/route53"
)

type DNS struct {
	Route53 *route53.Route53
	ZoneId  string
	Log     logging.Logger
}

func (d *DNS) DeleteDomain(domain, ip string) error {
	if !validator.IsValidDomain(domain) {
		return fmt.Errorf("deleting: domain name is not valid: %s", domain)
	}

	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Deleting domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "DELETE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     300,
					Records: []string{ip}, // needs old ip
				},
			},
		},
	}

	d.Log.Info("Deleting domain name: %s which was associated to ip %s %s",
		domain, ip)

	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

func (d *DNS) CreateDomain(domain, ip string) error {
	if !validator.IsValidDomain(domain) {
		return fmt.Errorf("creating: domain name is not valid: %s", domain)
	}

	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Creating domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "CREATE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     300,
					Records: []string{ip},
				},
			},
		},
	}

	d.Log.Info("Creating domain name: %s to be associated with ip: %s",
		domain, ip)

	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

func (p *Provider) InitDNS(opts *protocol.Machine) error {
	// If we have in cache use it
	if p.DNS != nil {
		return nil
	}

	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	a.Log.Info("Creating Route53 instance")
	dns := route53.New(
		aws.Auth{
			AccessKey: a.Creds.AccessKey,
			SecretKey: a.Creds.SecretKey,
		},
		aws.Regions[DefaultRegion],
	)

	a.Log.Info("Searching for hosted zone: %s", DefaultHostedZone)
	hostedZones, err := dns.ListHostedZones("", 100)
	if err != nil {
		return err
	}

	var zoneId string
	for _, hostedZone := range hostedZones.HostedZones {
		if !strings.Contains(hostedZone.Name, DefaultHostedZone) {
			continue
		}

		zoneId = route53.CleanZoneID(hostedZone.ID)
	}

	if zoneId == "" {
		return fmt.Errorf("Hosted zone with the name '%s' doesn't exist", "koding.io")
	}

	p.DNS = &DNS{
		Route53: dns,
		ZoneId:  zoneId,
		Log:     p.Log,
	}
	return nil
}
