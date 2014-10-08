package kloud

import (
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
)

type domainArgs struct {
	DomainName string
}

type domainFunc func(*protocol.Machine, *domainArgs) (interface{}, error)

func (k *Kloud) domainHandler(r *kite.Request, fn domainFunc) (resp interface{}, err error) {
	args := &domainArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.DomainName == "" {
		return nil, fmt.Errorf("domain name argument is empty")
	}

	//  change it that we don't leak information
	defer func() {
		if err != nil {
			k.Log.Error("Could not call '%s'. err: %s", r.Method, err)
			err = fmt.Errorf("Could not call '%s'. Please contact support", r.Method)
		}
	}()

	m, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

	// PreparMachine is locking for us, so unlock after we are done
	defer k.Locker.Unlock(m.Id)

	if m.IpAddress == "" {
		return nil, fmt.Errorf("ip address is not defined")
	}

	// fake eventer to avoid panics if someone tries to use the eventer
	m.Eventer = &eventer.Events{}

	if err := k.Domainer.Validate(args.DomainName, r.Username); err != nil {
		return nil, err
	}

	return fn(m, args)
}

func (k *Kloud) DomainAdd(r *kite.Request) (resp interface{}, reqErr error) {
	addFunc := func(m *protocol.Machine, args *domainArgs) (interface{}, error) {
		if _, err := k.Domainer.Get(args.DomainName); err != nil {
			return nil, fmt.Errorf("domain record does exists")
		}

		// now assign the machine ip to the given domain name
		if err := k.Domainer.Create(args.DomainName, m.IpAddress); err != nil {
			return nil, err
		}

		domain := &protocol.Domain{
			MachineId: m.Id,
			Name:      args.DomainName,
		}

		if err := k.DomainStorage.Add(domain); err != nil {
			return nil, err
		}

		return true, nil
	}

	return k.domainHandler(r, addFunc)
}

func (k *Kloud) DomainRemove(r *kite.Request) (resp interface{}, reqErr error) {
	removeFunc := func(m *protocol.Machine, args *domainArgs) (interface{}, error) {
		if err := k.Domainer.Delete(args.DomainName, m.IpAddress); err != nil {
			return nil, err
		}

		if err := k.DomainStorage.Delete(args.DomainName); err != nil {
			return nil, err
		}

		return true, nil
	}

	return k.domainHandler(r, removeFunc)
}

func (k *Kloud) DomainUnset(r *kite.Request) (resp interface{}, reqErr error) {
	unsetFunc := func(m *protocol.Machine, args *domainArgs) (interface{}, error) {
		if err := k.Domainer.Delete(args.DomainName, m.IpAddress); err != nil {
			return nil, err
		}

		return true, nil
	}

	return k.domainHandler(r, unsetFunc)
}

func (k *Kloud) DomainSet(r *kite.Request) (resp interface{}, reqErr error) {
	setFunc := func(m *protocol.Machine, args *domainArgs) (interface{}, error) {
		if err := k.Domainer.Create(args.DomainName, m.IpAddress); err != nil {
			return nil, err
		}

		return true, nil
	}

	return k.domainHandler(r, setFunc)
}
