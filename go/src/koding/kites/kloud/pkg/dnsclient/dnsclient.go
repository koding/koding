package dnsclient

import (
	"errors"
	"fmt"
	"path"
	"strings"

	"koding/kites/kloud/awscompat"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/dchest/validator"
	"github.com/koding/logging"
	oldaws "github.com/mitchellh/goamz/aws"
)

var ErrNoRecord = errors.New("no records available")

type Route53 struct {
	*route53.Route53
	hostedZone string
	ZoneId     string
	Log        logging.Logger
}

// NewRoute53Client initializes a new DNSClient interface instance based on AWS Route53
func NewRoute53Client(hostedZone string, auth oldaws.Auth) *Route53 {
	dns := route53.New(
		awscompat.NewSession(auth),
		aws.NewConfig().WithRegion("us-east-1"), // our route53 is based on this region, so we use it
	)
	dns.Client.Retryer = awscompat.Retry

	params := &route53.ListHostedZonesInput{
		MaxItems: aws.String("100"),
	}
	hostedZones, err := dns.ListHostedZones(params)
	if err != nil {
		panic(err)
	}

	var zoneId string
	var dnsName = hostedZone + "." // DNS name ends with a ".", e.g. "dev.koding.io."
	for _, h := range hostedZones.HostedZones {
		if aws.StringValue(h.Name) == dnsName {
			// The h.Id looks like "/hostedzone/Z2T644TMIB2JZM", we're interested
			// only in the last part - "Z2T644TMIB2JZM".
			if s := aws.StringValue(h.Id); s != "" {
				zoneId = path.Base(s)
			}
			break
		}
	}

	if zoneId == "" {
		panic(fmt.Sprintf("Hosted zone with the name '%s' doesn't exist", hostedZone))
	}

	return &Route53{
		Route53:    dns,
		hostedZone: hostedZone,
		ZoneId:     zoneId,
		Log:        logging.NewLogger("kloud-dns"),
	}
}

// Upsert creates or updates a the domain record with the given ip address. If
// the record already exists, the record is updated with the new IP.
func (r *Route53) Upsert(domain string, newIP string) error {
	r.Log.Debug("upserting domain name: %s to be associated with following ip: %v", domain, newIP)
	params := &route53.ChangeResourceRecordSetsInput{
		HostedZoneId: aws.String(r.ZoneId),
		ChangeBatch: &route53.ChangeBatch{
			Comment: aws.String("Upserting domain"),
			Changes: []*route53.Change{{
				Action: aws.String("UPSERT"),
				ResourceRecordSet: &route53.ResourceRecordSet{
					Name: aws.String(domain),
					Type: aws.String("A"),
					TTL:  aws.Int64(30),
					ResourceRecords: []*route53.ResourceRecord{{
						Value: aws.String(newIP),
					}},
				},
			}},
		},
	}
	_, err := r.ChangeResourceRecordSets(params)
	if err != nil {
		return r.errorf("could not upsert domain %q: ", domain, err)
	}
	return nil
}

// Domain retrieves the record set for the given domain name
func (r *Route53) Get(domain string) (*Record, error) {
	r.Log.Debug("fetching domain record for domain: %s", domain)
	resp, err := r.get(domain)
	if err != nil {
		return nil, r.error(err)
	}

	var dnsName = domain + "." // DNS name ends with a ".", e.g. "dev.koding.io."
	for _, r := range resp {
		if aws.StringValue(r.Name) == dnsName {
			return &Record{
				Name: aws.StringValue(r.Name),
				IP:   aws.StringValue(r.ResourceRecords[0].Value),
				TTL:  int(aws.Int64Value(r.TTL)),
			}, nil
		}
	}

	return nil, r.error(ErrNoRecord)
}

// GetAll retrieves all records from the hostedzone. Because of the limitation
// of Route53 it only returns up to 100 records. Subsequent calls retrieve the
// first 100.
func (r *Route53) GetAll(name string) ([]*Record, error) {
	r.Log.Debug("fetching domain records for name: %s", name)
	resp, err := r.get(name)
	if err != nil {
		return nil, r.error(err)
	}

	records := make([]*Record, len(resp))

	for i, r := range resp {
		records[i] = &Record{
			Name: aws.StringValue(r.Name),
			IP:   aws.StringValue(r.ResourceRecords[0].Value),
			TTL:  int(aws.Int64Value(r.TTL)),
		}
	}

	return records, nil
}

func (r *Route53) get(name string) ([]*route53.ResourceRecordSet, error) {
	params := &route53.ListResourceRecordSetsInput{
		HostedZoneId: aws.String(r.ZoneId),
	}
	if name != "" {
		params.StartRecordName = aws.String(name)
	}
	resp, err := r.ListResourceRecordSets(params)
	if err != nil {
		return nil, fmt.Errorf("could not fetch records for name %q: %s", name, err)
	}
	if len(resp.ResourceRecordSets) == 0 {
		return nil, ErrNoRecord
	}
	return resp.ResourceRecordSets, nil
}

// Rename changes the domain from oldDomain to newDomain in a single transaction
func (r *Route53) Rename(oldDomain, newDomain string) error {
	record, err := r.Get(oldDomain)
	if err != nil {
		return err
	}
	r.Log.Debug("updating domain name of IP %s from %q to %q", record.IP, oldDomain, newDomain)
	params := &route53.ChangeResourceRecordSetsInput{
		HostedZoneId: aws.String(r.ZoneId),
		ChangeBatch: &route53.ChangeBatch{
			Comment: aws.String("Renaming domain"),
			Changes: []*route53.Change{{
				Action: aws.String("DELETE"),
				ResourceRecordSet: &route53.ResourceRecordSet{
					Name: aws.String(oldDomain),
					Type: aws.String("A"),
					TTL:  aws.Int64(int64(record.TTL)),
					ResourceRecords: []*route53.ResourceRecord{{
						Value: aws.String(record.IP),
					}},
				},
			}, {
				Action: aws.String("UPSERT"),
				ResourceRecordSet: &route53.ResourceRecordSet{
					Name: aws.String(newDomain),
					Type: aws.String("A"),
					TTL:  aws.Int64(int64(record.TTL)),
					ResourceRecords: []*route53.ResourceRecord{{
						Value: aws.String(record.IP),
					}},
				},
			}},
		},
	}
	if _, err = r.ChangeResourceRecordSets(params); err != nil {
		return r.errorf("could not rename domain %q to %q: %s", oldDomain, newDomain, err)
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
	r.Log.Debug("deleting domain name: %s which was associated to following ip: %s", domain, record.IP)
	params := &route53.ChangeResourceRecordSetsInput{
		HostedZoneId: aws.String(r.ZoneId),
		ChangeBatch: &route53.ChangeBatch{
			Comment: aws.String("Renaming domain"),
			Changes: []*route53.Change{{
				Action: aws.String("DELETE"),
				ResourceRecordSet: &route53.ResourceRecordSet{
					Name: aws.String(domain),
					Type: aws.String("A"),
					TTL:  aws.Int64(int64(record.TTL)),
					ResourceRecords: []*route53.ResourceRecord{{
						Value: aws.String(record.IP),
					}},
				},
			}},
		},
	}
	if _, err = r.ChangeResourceRecordSets(params); err != nil {
		return r.errorf("could not delete domain %q: %s", domain, err)
	}
	return nil
}

func (r *Route53) HostedZone() string {
	return r.hostedZone
}

func (r *Route53) Validate(domain, username string) error {
	hostedZone := r.hostedZone

	if domain == "" {
		return r.errorf("Domain name argument is empty")
	}

	if domain == hostedZone {
		return r.errorf("Domain '%s' can't be the same as top-level domain '%s'", domain, hostedZone)
	}

	if !strings.Contains(domain, hostedZone) {
		return r.errorf("Domain doesn't contain hostedzone '%s'", hostedZone)
	}

	rest := strings.TrimSuffix(domain, "."+hostedZone)
	if rest == domain {
		return r.errorf("Domain is invalid (1) '%s'", domain)
	}

	if split := strings.Split(rest, "."); split[len(split)-1] != username {
		return r.errorf("Domain doesn't contain username '%s'", username)
	}

	if !validator.IsValidDomain(domain) {
		return r.errorf("Domain is invalid (2) '%s'", domain)
	}

	return nil
}

func (r *Route53) errorf(format string, v ...interface{}) error {
	err := fmt.Errorf(format, v...)
	r.Log.Error(err.Error())
	return err
}

func (r *Route53) error(err error) error {
	r.Log.Error(err.Error())
	return err
}
