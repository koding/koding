package koding

import (
	"errors"
	"fmt"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/mitchellh/goamz/ec2"
)

const (
	snapshotCollection = "jSnapshots"
)

// DomainDocument defines a single MongoDB document in the jSnapshots collection
type SnapshotDocument struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	MachineId  bson.ObjectId `bson:"machineId"`
	SnapshotId string        `bson:"snapshotId"`
	Region     string        `bson:"region"`
	CreatedAt  time.Time     `bson:"createdAt"`
}

func (p *Provider) DeleteSnapshot(snapshotId string, m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	p.Log.Info("[%s] deleting snapshot from AWS %s", m.Id, snapshotId)
	if _, err := a.Client.DeleteSnapshots([]string{snapshotId}); err != nil {
		return err
	}

	p.Log.Debug("[%s] deleting snapshot data from MongoDB %s", m.Id, snapshotId)
	return p.DeleteSnapshotData(snapshotId)
}

func (p *Provider) CreateSnapshot(m *protocol.Machine) (*protocol.Artifact, error) {
	checker, err := p.PlanChecker(m)
	if err != nil {
		return nil, err
	}

	if err := checker.SnapshotTotal(); err != nil {
		return nil, err
	}

	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	a.Push("Creating snapshot initialized", 10, machinestate.Snapshotting)
	instance, err := a.Instance(a.Id())
	if err != nil {
		return nil, err
	}

	if len(instance.BlockDevices) == 0 {
		return nil, fmt.Errorf("createSnapshot: no block device available")
	}

	if m.State != machinestate.Stopped {
		a.Log.Debug("[%s] Stopping machine for creating snapshot", m.Id)
		if err := a.Stop(false); err != nil {
			return nil, err
		}
	}

	volumeId := instance.BlockDevices[0].VolumeId
	snapshotDesc := fmt.Sprintf("user-%s-%s", m.Username, m.Id)

	a.Log.Debug("[%s] Creating snapshot '%s'", m.Id, snapshotDesc)
	a.Push("Creating snapshot", 40, machinestate.Snapshotting)
	snapshot, err := a.CreateSnapshot(volumeId, snapshotDesc)
	if err != nil {
		return nil, err
	}
	a.Log.Debug("[%s] Snapshot created successfully: %+v", m.Id, snapshot)

	if err := p.AddSnapshotData(snapshot.Id, a.Client.Region.Name, m.Id); err != nil {
		return nil, err
	}

	tags := []ec2.Tag{
		{Key: "Name", Value: snapshotDesc},
		{Key: "koding-user", Value: m.Username},
		{Key: "koding-machineId", Value: m.Id},
	}

	if _, err := a.Client.CreateTags([]string{snapshot.Id}, tags); err != nil {
		// don't return for a snapshot tag problem
		p.Log.Warning("[%s] Failed to tag the new snapshot: %v", m.Id, err)
	}

	a.Log.Debug("[%s] Starting the machine after snapshot creation", m.Id)
	a.Push("Starting instance", 70, machinestate.Snapshotting)
	// start the stopped instance now as we attached the new volume
	artifact, err := a.Start(false)
	if err != nil {
		return nil, err
	}

	a.Push("Updating domain", 85, machinestate.Snapshotting)
	// update Domain record with the new IP
	if err := p.UpdateDomain(artifact.IpAddress, m.Domain.Name, m.Username); err != nil {
		return nil, err
	}

	a.Push("Updating domain aliases", 87, machinestate.Snapshotting)
	// also get all domain aliases that belongs to this machine and unset
	domains, err := p.DomainStorage.GetByMachine(m.Id)
	if err != nil {
		p.Log.Error("[%s] fetching domains for unsetting err: %s", m.Id, err.Error())
	}

	for _, domain := range domains {
		if err := p.UpdateDomain(artifact.IpAddress, domain.Name, m.Username); err != nil {
			p.Log.Error("[%s] couldn't update domain: %s", m.Id, err.Error())
		}
	}

	a.Push("Checking connectivity", 90, machinestate.Snapshotting)
	artifact.DomainName = m.Domain.Name

	if p.IsKlientReady(m.QueryString) {
		p.Log.Debug("[%s] klient is ready.", m.Id)
	} else {
		p.Log.Warning("[%s] klient is not ready. I couldn't connect to it.", m.Id)
	}

	return artifact, nil
}

func (p *Provider) AddSnapshotData(snapshotId, region, machineId string) error {
	doc := &SnapshotDocument{
		Id:         bson.NewObjectId(),
		MachineId:  bson.ObjectIdHex(machineId),
		SnapshotId: snapshotId,
		Region:     region,
		CreatedAt:  time.Now().UTC(),
	}

	err := p.Session.Run(snapshotCollection, func(c *mgo.Collection) error {
		return c.Insert(doc)
	})

	if err != nil {
		p.Log.Error("[%s] Could not add snapshot %v: err: %v", machineId, doc, err)
		return errors.New("could not add snapshot to DB")
	}

	return nil

}

func (p *Provider) DeleteSnapshotData(snapshotId string) error {
	err := p.Session.Run(snapshotCollection, func(c *mgo.Collection) error {
		return c.Remove(bson.M{"snapshotId": snapshotId})
	})

	if err != nil {
		p.Log.Error("Could not delete %v: err: %v", snapshotId, err)
		return errors.New("could not delete snapshot from DB")
	}

	return nil
}
