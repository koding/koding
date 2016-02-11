package softlayer

import (
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

func (m *Machine) Reinit(ctx context.Context) (err error) {
	return m.guardTransition(machinestate.Starting, "Machine is starting", ctx, m.reinit)
}

func (m *Machine) reinit(ctx context.Context) error {
	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	// delete old domains
	if err := m.deleteDomains(); err != nil {
		m.Log.Warning("couldn't delete domains while reiniting machine: %s", err)
	}

	// go and terminate the old instance, we don't need to wait for it
	//Get the SoftLayer virtual guest service
	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}

	_, err = svc.DeleteObject(meta.Id)
	if err != nil {
		return err
	}

	// cleanup this too so "build" can continue with a clean setup
	// don't zero vlanID on reinit, as Softlayer won't update Vlan.GuestCount
	// fast enough for kloud to observe the old vm was destroyed.
	m.IpAddress = ""
	m.QueryString = ""
	m.Meta["id"] = 0
	m.Status.State = machinestate.NotInitialized.String()

	// this updates/creates domain
	return m.Build(ctx)
}
