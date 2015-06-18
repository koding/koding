package main

import (
	"errors"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/koding/logging"
)

const (
	// callerReferance is used as unique id for idempotency on aws side
	callerReferance         = "tunnelproxy_dev_2"
	hostedZoneName          = "tunnelproxy.koding.com"
	hostedZoneComment       = "Hosted zone for tunnel proxies"
	validStateForHostedZone = "INSYNC" // taken from aws response
)

var (
	errHostedZoneNotFound           = errors.New("hosted zone not found")
	errDeadlineReachedForChangeInfo = errors.New("deadline for change info")
)

// RecordManager manages Route53 records
type RecordManager struct {
	// aws services
	route53 *route53.Route53

	// application wide parameters
	hostedZone *route53.HostedZone
	region     string

	// general usage
	log logging.Logger
}

// New creates a RecordManager
func NewRecordManager(config *aws.Config, log logging.Logger, region string) (*RecordManager, error) {
	return &RecordManager{
		route53: route53.New(config),
		log:     log.New("recordmanager"),
		region:  region,
	}, nil
}

// Init initializes record manager's prerequisites
func (r *RecordManager) Init() error {
	r.log.Debug("init started")

	if err := r.ensureHostedZone(); err != nil {
		return err
	}

	r.log.Info("init is done")
	return nil
}

func (r *RecordManager) ensureHostedZone() error {
	hostedZoneLogger := r.log.New("HostedZone")
	hostedZoneLogger.Debug("working...")

	err := r.getHostedZone(hostedZoneLogger)
	if err != nil && err != errHostedZoneNotFound {
		return err
	}

	if err == errHostedZoneNotFound {
		hostedZoneLogger.Debug("Not found, creating...")
		err := r.createHostedZone(hostedZoneLogger)
		if err != nil {
			return err
		}
	}

	hostedZoneLogger.Debug("hosted zone is ready")

	return nil
}

func (r *RecordManager) getHostedZone(hostedZoneLogger logging.Logger) error {
	iteration := 0
	// try to get our hosted zone
	for {
		// just be paranoid about remove api calls, dont harden too much
		if iteration == 100 {
			return errors.New("iteration terminated")
		}

		log := hostedZoneLogger.New("iteration", iteration)

		iteration++

		// for pagination
		var nextMarker *string

		log.Debug("fetching hosted zone")
		listHostedZonesResp, err := r.route53.ListHostedZones(
			&route53.ListHostedZonesInput{
				Marker: nextMarker,
			}, // we dont have anything to filter
		)
		if err != nil {
			return err
		}

		if listHostedZonesResp == nil {
			return errors.New("malformed response")
		}

		for _, hostedZone := range listHostedZonesResp.HostedZones {
			if *hostedZone.CallerReference == callerReferance {
				r.hostedZone = hostedZone
				log.Debug("hosted zone found")
				return nil
			}
		}

		// if our result set is truncated we can try to fecth again, but if we
		// reach to end, nothing to do left
		if !*listHostedZonesResp.IsTruncated {
			return errHostedZoneNotFound
		}

		// assign next marker
		nextMarker = listHostedZonesResp.NextMarker
	}
}

// createHostedZone creates hosted zone and makes sure that it is in to be used
// state
func (r *RecordManager) createHostedZone(hostedZoneLogger logging.Logger) error {
	hostedZoneLogger.Debug("create hosted zone started")

	// CreateHostedZone is not idempotent, multiple calls to this function
	// result in duplicate records, fyi
	resp, err := r.route53.CreateHostedZone(&route53.CreateHostedZoneInput{
		CallerReference: aws.String(callerReferance),
		Name:            aws.String(hostedZoneName),
		HostedZoneConfig: &route53.HostedZoneConfig{
			Comment: aws.String(hostedZoneComment),
		},
	})
	if err != nil {
		return err
	}

	if resp == nil {
		return errors.New("malformed response, resp is nil")
	}

	changeInfo := resp.ChangeInfo
	deadline := time.After(time.Minute * 5) // at most i've seen ~3min

	// make sure it propagated
	for {
		// if our change propagated, we can return
		if *changeInfo.Status == validStateForHostedZone {
			hostedZoneLogger.Debug("hosted zone status is valid")
			break
		}

		select {
		case <-deadline:
			return errDeadlineReachedForChangeInfo
		default:
			time.Sleep(time.Second * 3) // poor man's throttling
			hostedZoneLogger.New("changeInfoID", *changeInfo.ID).Debug("fetching latest status")
			getChangeResp, err := r.route53.GetChange(&route53.GetChangeInput{
				ID: changeInfo.ID,
			})
			if err != nil {
				return err
			}

			if getChangeResp == nil {
				return errors.New("malformed response, getChangeResp is nil")
			}

			changeInfo = getChangeResp.ChangeInfo
		}
	}

	r.hostedZone = resp.HostedZone

	return nil
}

func (r *RecordManager) createRecordSet() error {
	if r.hostedZone == nil {
		return errors.New("hosted zone is not set")
	}

	params := &route53.ChangeResourceRecordSetsInput{
		ChangeBatch: &route53.ChangeBatch{
			Changes: []*route53.Change{
				&route53.Change{
					Action: aws.String("UPSERT"),
					ResourceRecordSet: &route53.ResourceRecordSet{
						Name:   aws.String(hostedZoneName),
						Type:   aws.String("A"),
						Region: aws.String(r.region),
						ResourceRecords: []*route53.ResourceRecord{
							// TODO these will be actual ip adreesses of proxy machines
							&route53.ResourceRecord{
								Value: aws.String("52.7.21.41"),
							},
							&route53.ResourceRecord{
								Value: aws.String("52.1.117.108"),
							},
						},
						// use region name as identifer
						SetIdentifier: aws.String(r.region),
						TTL:           aws.Long(1),
					},
				},
			},
			Comment: aws.String(
				fmt.Sprintf(
					"Record set for zone: %s region: %s",
					hostedZoneName,
					r.region,
				),
			),
		},
		HostedZoneID: r.hostedZone.ID,
	}

	_, err := r.route53.ChangeResourceRecordSets(params)
	if err != nil {
		return err
	}

	return nil
}
