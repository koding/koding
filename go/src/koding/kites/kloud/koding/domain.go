package koding

import (
	"errors"
	"fmt"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/protocol"
	"strings"
	"time"

	"labix.org/v2/mgo/bson"

	"github.com/dchest/validator"
	"github.com/koding/kite"
)

type domainArgs struct {
	DomainName string
}

func (p *Provider) DomainAdd(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	args := &domainArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.DomainName == "" {
		return nil, errors.New("domain name argument is empty")
	}

	if p.DNS == nil {
		// just call it initialize DNS struct
		_, err := p.NewClient(m)
		if err != nil {
			return nil, err
		}
	}

	if err := validateDomain(args.DomainName, r.Username, p.DNS.HostedZone); err != nil {
		return nil, err
	}

	// nil error means the record exist
	if _, err := p.DNS.Domain(args.DomainName); err == nil {
		return nil, errors.New("domain record does exists")
	}

	if m.IpAddress == "" {
		return nil, errors.New("ip address is not defined")
	}

	// now assign the machine ip to the given domain name
	if err := p.DNS.CreateDomain(args.DomainName, m.IpAddress); err != nil {
		return nil, err
	}

	domainDocument := &DomainDocument{
		Id:         bson.NewObjectId(),
		MachineId:  bson.ObjectIdHex(m.Id),
		DomainName: args.DomainName,
		CreatedAt:  time.Now().UTC(),
	}

	fmt.Printf("domainDocument %+v\n", domainDocument)

	if err := p.DomainStorage.Add(domainDocument); err != nil {
		return nil, err
	}

	return true, nil
}

func (p *Provider) DomainRemove(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	args := &domainArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.DomainName == "" {
		return nil, errors.New("domain name argument is empty")
	}

	return nil, err
}

func (p *Provider) DomainUnset(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	return nil, err
}

func (p *Provider) DomainSet(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	args := &domainArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.DomainName == "" {
		return nil, fmt.Errorf("domain name argument is empty")
	}

	if p.DNS == nil {
		// just call it initialize DNS struct
		_, err := p.NewClient(m)
		if err != nil {
			return nil, err
		}
	}

	if err := validateDomain(args.DomainName, r.Username, p.DNS.HostedZone); err != nil {
		return nil, err
	}

	if err := p.DNS.CreateDomain(args.DomainName, m.IpAddress); err != nil {
		return nil, err
	}

	if err := p.Update(m.Id, &kloud.StorageData{
		Type: "domain",
		Data: map[string]interface{}{
			"domainName": args.DomainName,
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
	if err := validateDomain(domain, username, p.DNS.HostedZone); err != nil {
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
