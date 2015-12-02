package softlayer

import (
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

func (m *Machine) Reinit(ctx context.Context) (err error) {
	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	// go and terminate the old instance, we don't need to wait for it
	go func(id int) {
		//Get the SoftLayer virtual guest service
		svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
		if err != nil {
			m.Log.Warning("couldn't terminate instance (code 1)")
			return
		}

		_, err = svc.DeleteObject(id)
		if err != nil {
			m.Log.Warning("couldn't terminate instance (code 2)")
		}
	}(meta.Id)

	// cleanup this too so "build" can continue with a clean setup
	m.IpAddress = ""
	m.QueryString = ""
	m.Meta["id"] = 0
	m.Status.State = machinestate.NotInitialized.String()

	// this updates/creates domain
	return m.Build(ctx)
}
