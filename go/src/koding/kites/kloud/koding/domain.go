package koding

import (
	"errors"
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/protocol"
	"strings"

	"github.com/dchest/validator"
	"github.com/koding/kite"
)

func (p *Provider) DomainAdd(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	return nil, err
}

func (p *Provider) DomainRemove(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	return nil, err
}

func (p *Provider) DomainUnset(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	return nil, err
}

func (p *Provider) DomainSet(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	defer p.Unlock(m.Id) // reset assignee after we are done

	args := &domainSet{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	m.Eventer = &eventer.Events{}

	if args.NewDomain == "" {
		return nil, fmt.Errorf("newDomain argument is empty")
	}

	defer func() {
		if err != nil {
			p.Log.Error("Could not update domain. err: %s", err)

			//  change it that we don't leak information
			err = errors.New("Could not set domain. Please contact support")
		}
	}()

	if p.DNS == nil {
		// just call it initialize DNS struct
		_, err := p.NewClient(m)
		if err != nil {
			return nil, err
		}
	}

	if err := validateDomain(args.NewDomain, r.Username, p.HostedZone); err != nil {
		return nil, err
	}

	if err := p.DNS.Rename(m.Domain.Name, args.NewDomain, m.IpAddress); err != nil {
		return nil, err
	}

	if err := p.Update(m.Id, &kloud.StorageData{
		Type: "domain",
		Data: map[string]interface{}{
			"domainName": args.NewDomain,
		},
	}); err != nil {
		return nil, err
	}

	return true, nil
}

// UpdateDomain sets the ip to the given domain. If there is no record a new
// record will be created otherwise existing record is updated. This is just a
// helper method that uses our DNS struct.
func (p *Provider) UpdateDomain(ip, domain, username string) error {
	if err := validateDomain(domain, username, p.HostedZone); err != nil {
		return err
	}

	// Check if the record exist, if yes update the ip instead of creating a new one.
	record, err := p.DNS.Domain(domain)
	if err == ErrNoRecord {
		if err := p.DNS.CreateDomain(domain, ip); err != nil {
			return err
		}
	} else if err != nil {
		// If it's something else just return it
		return err
	}

	// Means the record exist, update it
	if err == nil {
		p.Log.Warning("Domain '%s' already exists (that shouldn't happen). Going to update to new IP", domain)
		if err := p.DNS.Update(domain, record.Records[0], ip); err != nil {
			return err
		}
	}

	return nil
}

func validateDomain(domain, username, hostedZone string) error {
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
