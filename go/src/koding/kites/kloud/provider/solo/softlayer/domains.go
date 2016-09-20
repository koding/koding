package softlayer

import "koding/kites/kloud/machinestate"

func (m *Machine) deleteDomains() error {
	m.push("Initializing domain instance", 65, machinestate.Stopping)
	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		return err
	}

	m.push("Changing domain to sleeping mode", 85, machinestate.Stopping)
	if err := m.Session.DNSClient.Delete(m.Domain); err != nil {
		m.Log.Warning("couldn't delete domain %s", err)
	}

	// also get all domain aliases that belongs to this machine and unset
	domains, err := m.Session.DNSStorage.GetByMachine(m.ObjectId.Hex())
	if err != nil {
		m.Log.Error("fetching domains for unseting err: %s", err)
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Delete(domain.Name); err != nil {
			m.Log.Warning("couldn't delete domain %s", err)
		}
	}

	return nil
}

func (m *Machine) addDomains() error {
	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		return err
	}

	if err := m.Session.DNSClient.Upsert(m.Domain, m.IpAddress); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err)
	}

	m.push("Updating domain aliases", 72, machinestate.Building)
	domains, err := m.Session.DNSStorage.GetByMachine(m.ObjectId.Hex())
	if err != nil {
		m.Log.Error("fetching domains for setting err: %s", err)
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Validate(domain.Name, m.Username); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err)
			continue
		}
		if err := m.Session.DNSClient.Upsert(domain.Name, m.IpAddress); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err)
		}
	}
	return nil
}
