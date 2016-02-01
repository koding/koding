package dnsclient

import (
	"errors"
	"fmt"
	"path"
	"strings"
	"time"

	"koding/kites/kloud/api/amazon"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/cenkalti/backoff"
	"github.com/dchest/validator"
	"github.com/koding/logging"
)

var ErrNoRecord = errors.New("no records available")

var defaultLog = logging.NewLogger("kloud-dns")

type Route53 struct {
	*route53.Route53
	hostedZone string
	ZoneId     string
	Log        logging.Logger

	sync time.Duration
}

type Options struct {
	Creds      *credentials.Credentials
	HostedZone string
	Log        logging.Logger

	// SyncTimeout tells at most how much time we're going to wait
	// till DNS change is propageted on all Amazon servers.
	//
	// 0 means we're not waiting at all.
	SyncTimeout time.Duration
}

func (opts *Options) log() logging.Logger {
	if opts.Log != nil {
		return opts.Log
	}
	return defaultLog
}

// NewRoute53Client initializes a new DNSClient interface instance based on AWS Route53
func NewRoute53Client(opts *Options) (*Route53, error) {
	awsOpts := &amazon.ClientOptions{
		Credentials: opts.Creds,
		Region:      "us-east-1", // our route53 is based on this region, so we use it
		Log:         opts.log(),
	}
	dns := route53.New(amazon.NewSession(awsOpts))

	// TODO(rjeczalik): filter by hosted zone instead of requesting 100 records
	params := &route53.ListHostedZonesInput{
		MaxItems: aws.String("100"),
	}
	hostedZones, err := dns.ListHostedZones(params)
	if err != nil {
		return nil, err
	}

	var zoneId string
	var dnsName = opts.HostedZone + "." // DNS name ends with a ".", e.g. "dev.koding.io."
	for _, h := range hostedZones.HostedZones {
		if aws.StringValue(h.Name) == dnsName {
			// The h.Id looks like "/hostedzone/Z2T644TMIB2JZM", we're interested
			// only in the last part - "Z2T644TMIB2JZM".
			if s := aws.StringValue(h.Id); s != "" {
				zoneId = path.Base(s)
			}
		}
	}

	if zoneId == "" {
		return nil, fmt.Errorf("Hosted zone with the name %q doesn't exist", opts.HostedZone)
	}

	return &Route53{
		Route53:    dns,
		hostedZone: opts.HostedZone,
		ZoneId:     zoneId,
		Log:        opts.log(),
		sync:       opts.SyncTimeout,
	}, nil
}

// Upsert creates or updates the domain record with the given ip address. If
// the record already exists, the record is updated with the new IP.
func (r *Route53) Upsert(domain, newIP string) error {
	rec := &Record{
		Name: domain,
		Type: "A",
		IP:   newIP,
		TTL:  30,
	}
	return r.UpsertRecord(rec)
}

// UpsertRecord creates or updates a DNS record.
func (r *Route53) UpsertRecord(rec *Record) error {
	r.Log.Debug("upserting record: %# v", rec)
	params := &route53.ChangeResourceRecordSetsInput{
		HostedZoneId: aws.String(r.ZoneId),
		ChangeBatch: &route53.ChangeBatch{
			Comment: aws.String("Upserting domain"),
			Changes: []*route53.Change{{
				Action: aws.String("UPSERT"),
				ResourceRecordSet: &route53.ResourceRecordSet{
					Name: aws.String(rec.Name),
					Type: aws.String(rec.Type),
					TTL:  aws.Int64(int64(rec.TTL)),
					ResourceRecords: []*route53.ResourceRecord{{
						Value: aws.String(rec.IP),
					}},
				},
			}},
		},
	}
	return r.change(params)
}

func (r *Route53) change(params *route53.ChangeResourceRecordSetsInput) error {
	comment := aws.StringValue(params.ChangeBatch.Comment)
	resp, err := r.ChangeResourceRecordSets(params)
	if err != nil {
		return r.errorf("%s failed: %s", comment, err)
	}

	return r.wait(r.sync, comment, aws.StringValue(resp.ChangeInfo.Id))
}

func (r *Route53) wait(timeout time.Duration, comment, id string) error {
	if timeout == 0 {
		return nil
	}

	retry := backoff.NewExponentialBackOff()
	retry.MaxElapsedTime = timeout
	retry.Reset()

	change := &route53.GetChangeInput{
		Id: aws.String(id),
	}
	for {
		resp, err := r.GetChange(change)
		var status string
		if err == nil && resp.ChangeInfo != nil {
			status = strings.ToLower(aws.StringValue(resp.ChangeInfo.Status))
		}

		r.Log.Debug("%s: checking %s status=%s, err=%v", comment, id, status, err)

		if status == "insync" {
			return nil
		}

		next := retry.NextBackOff()
		if next == backoff.Stop {
			return fmt.Errorf("waiting for %s status to be insync timed out", id)
		}
		time.Sleep(next)
	}
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
				Type: aws.StringValue(r.Type),
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
			Type: aws.StringValue(r.Type),
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
		return nil, fmt.Errorf("could not fetch records for name %q: %q", name, err)
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
					Type: aws.String(record.Type),
					TTL:  aws.Int64(int64(record.TTL)),
					ResourceRecords: []*route53.ResourceRecord{{
						Value: aws.String(record.IP),
					}},
				},
			}, {
				Action: aws.String("UPSERT"),
				ResourceRecordSet: &route53.ResourceRecordSet{
					Name: aws.String(newDomain),
					Type: aws.String(record.Type),
					TTL:  aws.Int64(int64(record.TTL)),
					ResourceRecords: []*route53.ResourceRecord{{
						Value: aws.String(record.IP),
					}},
				},
			}},
		},
	}
	if _, err = r.ChangeResourceRecordSets(params); err != nil {
		return r.errorf("could not rename domain %q to %q: %q", oldDomain, newDomain, err)
	}
	return nil
}

// DeleteDomain deletes a domain record for the given domain.
func (r *Route53) Delete(domain string) error {
	rec, err := r.Get(domain)
	if err != nil {
		// domains can be removed via other bussiness logics, so this can
		// happen
		if err == ErrNoRecord {
			return nil
		}
		return err
	}
	return r.DeleteRecord(rec)
}

// DeleteRecord deletes the given record.
func (r *Route53) DeleteRecord(rec *Record) error {
	r.Log.Debug("deleting record: %v", rec)
	params := &route53.ChangeResourceRecordSetsInput{
		HostedZoneId: aws.String(r.ZoneId),
		ChangeBatch: &route53.ChangeBatch{
			Comment: aws.String("Renaming domain"),
			Changes: []*route53.Change{{
				Action: aws.String("DELETE"),
				ResourceRecordSet: &route53.ResourceRecordSet{
					Name: aws.String(rec.Name),
					Type: aws.String(rec.Type),
					TTL:  aws.Int64(int64(rec.TTL)),
					ResourceRecords: []*route53.ResourceRecord{{
						Value: aws.String(rec.IP),
					}},
				},
			}},
		},
	}
	if _, err := r.ChangeResourceRecordSets(params); err != nil {
		return r.errorf("could not delete record %v: %s", rec, err)
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
		return r.errorf("Domain %q can't be the same as top-level domain %q", domain, hostedZone)
	}

	if !strings.Contains(domain, hostedZone) {
		return r.errorf("Domain %q doesn't contain hostedzone %q", domain, hostedZone)
	}

	rest := strings.TrimSuffix(domain, "."+hostedZone)
	if rest == domain {
		return r.errorf("Domain %q is invalid (1)", domain)
	}

	if split := strings.Split(rest, "."); split[len(split)-1] != username {
		return r.errorf("Domain %q doesn't contain %q username (hostedZone=%q)", domain, username, hostedZone)
	}

	if !validator.IsValidDomain(domain) {
		return r.errorf("Domain %q is invalid (2)", domain)
	}

	return nil
}

func (r *Route53) errorf(format string, v ...interface{}) error {
	err := fmt.Errorf(format, v...)
	r.Log.Error(err.Error())
	return err
}

func (r *Route53) error(err error) error {
	// Ignore ErrNoRecord errors, as they're expected
	// and handled by the caller.
	if err != ErrNoRecord {
		r.Log.Error("%q", err)
	}
	return err
}
