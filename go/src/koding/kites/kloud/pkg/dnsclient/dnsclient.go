package dnsclient

import (
	"errors"
	"fmt"
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
	ZoneId string

	opts *Options
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
	Debug       bool
}

func (opts *Options) log() logging.Logger {
	if opts.Log != nil {
		return opts.Log
	}
	return defaultLog
}

// NewRoute53Client initializes a new DNSClient interface instance based on AWS Route53
func NewRoute53Client(opts *Options) (*Route53, error) {
	optsCopy := *opts

	awsOpts := &amazon.ClientOptions{
		Credentials: opts.Creds,
		Region:      "us-east-1", // our route53 is based on this region, so we use it
		Log:         optsCopy.log(),
		Debug:       opts.Debug,
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
			zoneId = aws.StringValue(h.Id)
		}
	}

	if zoneId == "" {
		return nil, fmt.Errorf("Hosted zone with the name %q doesn't exist", opts.HostedZone)
	}

	return &Route53{
		Route53: dns,
		ZoneId:  zoneId,
		opts:    &optsCopy,
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
	return r.UpsertRecords(rec)
}

func (r *Route53) UpsertRecords(recs ...*Record) error {
	changes := make([]*route53.Change, len(recs))

	for i := range changes {
		r.opts.Log.Debug("upserting record: %# v", recs[i])

		changes[i] = &route53.Change{
			Action: aws.String("UPSERT"),
			ResourceRecordSet: &route53.ResourceRecordSet{
				Name: aws.String(recs[i].Name),
				Type: aws.String(recs[i].Type),
				TTL:  aws.Int64(int64(recs[i].TTL)),
				ResourceRecords: []*route53.ResourceRecord{{
					Value: aws.String(recs[i].IP),
				}},
			},
		}
	}

	params := &route53.ChangeResourceRecordSetsInput{
		HostedZoneId: aws.String(r.ZoneId),
		ChangeBatch: &route53.ChangeBatch{
			Comment: aws.String("Upserting domains"),
			Changes: changes,
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

	id := aws.StringValue(resp.ChangeInfo.Id)

	if r.opts.SyncTimeout == 0 && r.opts.Debug {
		// If no timeout is requested and we're in debug mode,
		// show DNS operation progress.
		go r.wait(5*time.Minute, comment, id)
		return nil
	}

	return r.wait(r.opts.SyncTimeout, comment, id)
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

		r.opts.Log.Debug("%s: checking %s status=%s, err=%v", comment, id, status, err)

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
	r.opts.Log.Debug("fetching domain record for domain: %s", domain)
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
	r.opts.Log.Debug("fetching domain records for name: %s", name)
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
	r.opts.Log.Debug("updating domain name of IP %s from %q to %q", record.IP, oldDomain, newDomain)
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
		// domains can be removed via other business logics, so this can
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
	r.opts.Log.Debug("deleting record: %v", rec)
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
	return r.opts.HostedZone
}

func (r *Route53) Validate(domain, username string) error {
	hostedZone := r.HostedZone()

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
	r.opts.Log.Error(err.Error())
	return err
}

func (r *Route53) error(err error) error {
	// Ignore ErrNoRecord errors, as they're expected
	// and handled by the caller.
	if err != ErrNoRecord {
		r.opts.Log.Error("%q", err)
	}
	return err
}
