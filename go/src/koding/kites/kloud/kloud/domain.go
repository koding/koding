package kloud

import (
	"fmt"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
)

type domainArgs struct {
	DomainName string
	MachineId  string
	recovery   bool
}

type domainFunc func(*protocol.Machine, *domainArgs) (interface{}, error)

func (k *Kloud) domainHandler(r *kite.Request, fn domainFunc) (resp interface{}, err error) {
	args := &domainArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if err := k.Domainer.Validate(args.DomainName, r.Username); err != nil {
		return nil, err
	}

	m, err := k.PrepareMachine(r)
	if err != nil && err != ErrMachineDocNotFound {
		return nil, err
	}

	if err != ErrMachineDocNotFound {
		// PrepareMachine is locking for us, so unlock after we are done
		defer k.Locker.Unlock(m.Id)

		if m.IpAddress == "" {
			return nil, fmt.Errorf("ip address is not defined")
		}

		// fake eventer to avoid panics if someone tries to use the eventer
		m.Eventer = &eventer.Events{}
	} else {
		// Enter the recovery mode where a machine document is not found by the
		// given machineId
		args.recovery = true
	}

	return fn(m, args)
}

func (k *Kloud) DomainAdd(r *kite.Request) (resp interface{}, reqErr error) {
	addFunc := func(m *protocol.Machine, args *domainArgs) (interface{}, error) {
		// a non nil means the domain exists
		if _, err := k.Domainer.Get(args.DomainName); err == nil {
			return nil, fmt.Errorf("domain record already exists")
		}

		// now assign the machine ip to the given domain name
		k.Log.Info("[%s] Adding domain '%s' to the machine", args.MachineId, args.DomainName)
		if err := k.Domainer.Create(args.DomainName, m.IpAddress); err != nil {
			k.Log.Warning("[%s] Adding domain '%s' to the machine failed. Err: %v",
				args.MachineId, args.DomainName, err)
			return nil, err
		}

		domain := &protocol.Domain{
			Username:  m.Username,
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
		k.Log.Info("[%s] Removing domain '%s' from the machine", args.MachineId, args.DomainName)
		// do not return on error because it might be already deleted via unset
		k.Domainer.Delete(args.DomainName, m.IpAddress)

		if err := k.DomainStorage.Delete(args.DomainName); err != nil {
			return nil, err
		}

		return true, nil
	}

	return k.domainHandler(r, removeFunc)
}

func (k *Kloud) DomainUnset(r *kite.Request) (resp interface{}, reqErr error) {
	unsetFunc := func(m *protocol.Machine, args *domainArgs) (interface{}, error) {
		// be sure the domain does exist in storage before we delete the domain
		//
		// TODO: We can make it better if we remove the document instead of returning an error.
		_, err := k.DomainStorage.Get(args.DomainName)
		if err != nil {
			return nil, fmt.Errorf("Domain document does not exist")
		}

		var ipAddr string

		// recovery is a flag, raised when a jMachine document is not found with the
		// given machineId.
		// We don't have the machine IPAddress because the machine document is
		// not there, so we try to complete the request by finding the actual
		// machine IP from the Domain provider, and removing the associated
		// record set.
		if args.recovery {
			record, err := k.Domainer.Get(args.DomainName)
			if err != nil {
				return nil, err
			}
			ipAddr = record.IP
		} else {
			ipAddr = m.IpAddress
		}

		k.Log.Info("[%s] Unsetting domain '%s' from the machine", args.MachineId, args.DomainName)
		if err := k.Domainer.Delete(args.DomainName, ipAddr); err != nil {
			k.Log.Warning("[%s] Unsetting domain '%s' from the machine failed. Err: %v",
				args.MachineId, args.DomainName, err)
			return nil, err
		}

		// Remove the machineId for the given domain. The document is still
		// there, but isn't associated with this domain anymore.
		if err := k.DomainStorage.UpdateMachine(args.DomainName, ""); err != nil {
			return nil, err
		}

		return true, nil
	}

	return k.domainHandler(r, unsetFunc)
}

func (k *Kloud) DomainSet(r *kite.Request) (resp interface{}, reqErr error) {
	setFunc := func(m *protocol.Machine, args *domainArgs) (interface{}, error) {
		// be sure the domain does exist in storage before we create the domain
		//
		// TODO: We can make it better if we create a document instead of returning an error.
		if _, err := k.DomainStorage.Get(args.DomainName); err != nil {
			return nil, fmt.Errorf("Domain document does not exist")
		}

		k.Log.Info("[%s] Setting domain '%s' to the machine", args.MachineId, args.DomainName)
		if err := k.Domainer.Create(args.DomainName, m.IpAddress); err != nil {
			k.Log.Warning("[%s] Setting domain '%s' to the machine failed. Err: %v",
				args.MachineId, args.DomainName, err)
			return nil, err
		}

		// adding the machineID for the given domain.
		if err := k.DomainStorage.UpdateMachine(args.DomainName, m.Id); err != nil {
			return nil, err
		}

		return true, nil
	}

	return k.domainHandler(r, setFunc)
}
