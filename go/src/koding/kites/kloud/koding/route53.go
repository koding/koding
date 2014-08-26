package koding

import (
	"errors"
	"fmt"
	"strings"

	"github.com/dchest/validator"
	"github.com/koding/kite"
	"github.com/koding/kloud"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/protocol"
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

	d.Log.Info("Updating name of IP %s from %v to %v", currentIP, oldDomain, newDomain)

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

	d.Log.Info("Updating domain %s IP from %v to %v",
		domain, oldIP, newIP)

	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

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

	d.Log.Info("Deleting domain name: %s which was associated to following ips: %v",
		domain, ips)

	_, err := d.Route53.ChangeResourceRecordSets(d.ZoneId, change)
	if err != nil {
		return err
	}

	return nil
}

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

	d.Log.Info("Creating domain name: %s to be associated with following ips: %v",
		domain, ips)

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

	d.Log.Info("Fetching domain record for name: %s", domain)

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

func (p *Provider) InitDNS(opts *protocol.Machine) error {
	// If we have in cache use it
	if p.DNS != nil {
		return nil
	}

	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	a.Log.Debug("Creating Route53 instance")
	dns := route53.New(
		aws.Auth{
			AccessKey: a.Creds.AccessKey,
			SecretKey: a.Creds.SecretKey,
		},
		aws.Regions[DefaultRegion],
	)

	a.Log.Info("Searching for hosted zone: %s", p.HostedZone)
	hostedZones, err := dns.ListHostedZones("", 100)
	if err != nil {
		return err
	}

	var zoneId string
	for _, h := range hostedZones.HostedZones {
		// the "." point is here because hosteded zones are listed as
		// "dev.koding.io." , "koding.io." and so on
		if !strings.HasSuffix(h.Name, p.HostedZone+".") {
			continue
		}

		zoneId = route53.CleanZoneID(h.ID)
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

type domainSet struct {
	NewDomain string
}

func (p *Provider) DomainSet(r *kite.Request, c *kloud.Controller) (interface{}, error) {
	defer p.ResetAssignee(c.MachineId) // reset assignee after we are done

	args := &domainSet{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	c.Eventer = &eventer.Events{}

	machineData, ok := c.Machine.CurrentData.(*Machine)
	if !ok {
		p.Log.Error("Could not update domain. Machine data is malformed: %v", c.Machine)
		return nil, fmt.Errorf("machine data is malformed. Please contact support.")
	}

	if args.NewDomain == "" {
		return nil, fmt.Errorf("newDomain argument is empty")
	}

	if err := p.InitDNS(c.Machine); err != nil {
		return nil, err
	}

	if err := p.DNS.Rename(machineData.Domain, args.NewDomain, machineData.IpAddress); err != nil {
		return nil, err
	}

	return fmt.Sprintf("Domain is updated to %s", args.NewDomain), nil
}

func validateDomain(domain, username, hostedZone string) error {
	f := strings.TrimSuffix(domain, "."+username+"."+hostedZone)
	if f == domain {
		return fmt.Errorf("Domain is invalid '%s'", domain)
	}

	if !strings.Contains(domain, username) {
		return fmt.Errorf("Domain doesn't contain username '%s'", username)
	}

	if !strings.Contains(domain, hostedZone) {
		return fmt.Errorf("Domain doesn't contain hostedzone '%s'", hostedZone)
	}

	if !validator.IsValidDomain(domain) {
		return fmt.Errorf("Domain is invalid '%s'", domain)
	}

	return nil
}
