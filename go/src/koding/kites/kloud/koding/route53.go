package koding

import (
	"fmt"
	"strings"

	"github.com/koding/kloud/protocol"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/route53"
)

type DNS struct {
	Route53 *route53.Route53
	ZoneId  string
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

	p.DNS = &DNS{Route53: dns, ZoneId: zoneId}
	return nil
}
