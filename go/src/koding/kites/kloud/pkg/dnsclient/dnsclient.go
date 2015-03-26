package dnsclient

import (
	"errors"
	"fmt"
	"strings"

	"github.com/dchest/validator"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/route53"
)

var ErrNoRecord = errors.New("no records available")

type Route53 struct {
	*route53.Route53
	hostedZone string
	ZoneId     string
	Log        logging.Logger
}

// NewRoute53Client initializes a new DNSClient interface instance based on AWS Route53
func NewRoute53Client(hostedZone string, auth aws.Auth) *Route53 {
	// our route53 is based on this region, so we use it
	dns := route53.New(auth, aws.USEast)

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

	r := &Route53{
		hostedZone: hostedZone,
		ZoneId:     zoneId,
		Log:        logging.NewLogger("kloud-dns"),
	}
	r.Route53 = dns
	return r
}

// Upsert creates or updates a the domain record with the given ip address. If
// the record already exists, the record is updated with the new IP.
func (r *Route53) Upsert(domain string, newIP string) error {
	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Upserting domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "UPSERT",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     30,
					Records: []string{newIP},
				},
			},
		},
	}

	r.Log.Debug("upserting domain name: %s to be associated with following ip: %v", domain, newIP)
	_, err := r.ChangeResourceRecordSets(r.ZoneId, change)
	if err != nil {
		r.Log.Error(err.Error())
		return errors.New("could not create domain")
	}

	return nil
}

// Domain retrieves the record set for the given domain name
func (r *Route53) Get(domain string) (*Record, error) {
	lopts := &route53.ListOpts{
		Name: domain,
	}

	r.Log.Debug("fetching domain record for name: %s", domain)

	resp, err := r.ListResourceRecordSets(r.ZoneId, lopts)
	if err != nil {
		r.Log.Error(err.Error())
		return nil, errors.New("could not fetch domain")
	}

	if len(resp.Records) == 0 {
		return nil, ErrNoRecord
	}

	for _, r := range resp.Records {
		// the "." point is here because records are listed as
		// "arslan.koding.io." , "test.arslan.dev.koding.io." and so on
		if strings.TrimSuffix(r.Name, ".") == domain {
			return &Record{
				Name: r.Name,
				IP:   r.Records[0],
				TTL:  r.TTL,
			}, nil
		}
	}

	return nil, ErrNoRecord
}

// Rename changes the domain from oldDomain to newDomain in a single transaction
func (r *Route53) Rename(oldDomain, newDomain string) error {
	record, err := r.Get(oldDomain)
	if err != nil {
		return err
	}

	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Renaming domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "DELETE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    oldDomain,
					TTL:     record.TTL,
					Records: []string{record.IP},
				},
			},
			route53.Change{
				Action: "UPSERT",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    newDomain,
					TTL:     record.TTL,
					Records: []string{record.IP},
				},
			},
		},
	}

	r.Log.Debug("updating domain name of IP %s from %v to %v", record.IP, oldDomain, newDomain)
	_, err = r.ChangeResourceRecordSets(r.ZoneId, change)
	if err != nil {
		r.Log.Error(err.Error())
		return errors.New("could not rename domain")
	}

	return nil
}

// DeleteDomain deletes a domain record for the given domain
func (r *Route53) Delete(domain string) error {
	// fetch correct TTL value, instead of relying on a hardcoded value for TTL
	// and IP
	record, err := r.Get(domain)
	if err != nil {
		return err
	}

	change := &route53.ChangeResourceRecordSetsRequest{
		Comment: "Deleting domain",
		Changes: []route53.Change{
			route53.Change{
				Action: "DELETE",
				Record: route53.ResourceRecordSet{
					Type:    "A",
					Name:    domain,
					TTL:     record.TTL,
					Records: []string{record.IP},
				},
			},
		},
	}

	r.Log.Debug("deleting domain name: %s which was associated to following ip: %v", domain, record.IP)
	_, err = r.ChangeResourceRecordSets(r.ZoneId, change)
	if err != nil {
		r.Log.Error(err.Error())
		return errors.New("could not delete domain")
	}

	return nil
}

func (r *Route53) HostedZone() string {
	return r.hostedZone
}

func (r *Route53) Validate(domain, username string) error {
	hostedZone := r.hostedZone

	if domain == "" {
		return fmt.Errorf("Domain name argument is empty")
	}

	if domain == hostedZone {
		return fmt.Errorf("Domain '%s' can't be the same as top-level domain '%s'", domain, hostedZone)
	}

	if !strings.Contains(domain, hostedZone) {
		return fmt.Errorf("Domain doesn't contain hostedzone '%s'", hostedZone)
	}

	rest := strings.TrimSuffix(domain, "."+hostedZone)
	if rest == domain {
		return fmt.Errorf("Domain is invalid (1) '%s'", domain)
	}

	if split := strings.Split(rest, "."); split[len(split)-1] != username {
		return fmt.Errorf("Domain doesn't contain username '%s'", username)
	}

	if !validator.IsValidDomain(domain) {
		return fmt.Errorf("Domain is invalid (2) '%s'", domain)
	}

	return nil
}
