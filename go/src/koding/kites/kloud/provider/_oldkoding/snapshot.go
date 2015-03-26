package oldkoding

import (
	"errors"
	"fmt"
	"koding/db/models"
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
	OriginId   bson.ObjectId `bson:"originId"`
	MachineId  bson.ObjectId `bson:"machineId"`
	SnapshotId string        `bson:"snapshotId"`
	Region     string        `bson:"region"`
	CreatedAt  time.Time     `bson:"createdAt"`
	username   string        `bson:"-"`
}

func (p *Provider) DeleteSnapshot(snapshotId string, m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	a.Log.Info("deleting snapshot from AWS %s", snapshotId)
	if _, err := a.Client.DeleteSnapshots([]string{snapshotId}); err != nil {
		return err
	}

	a.Log.Debug("deleting snapshot data from MongoDB %s", snapshotId)
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

	volumeId := instance.BlockDevices[0].VolumeId
	snapshotDesc := fmt.Sprintf("user-%s-%s", m.Username, m.Id)

	a.Log.Debug("Creating snapshot '%s'", snapshotDesc)
	a.Push("Creating snapshot", 50, machinestate.Snapshotting)
	snapshot, err := a.CreateSnapshot(volumeId, snapshotDesc)
	if err != nil {
		return nil, err
	}
	a.Log.Debug("Snapshot created successfully: %+v", snapshot)

	snapshotData := &SnapshotDocument{
		username:   m.Username,
		Region:     a.Client.Region.Name,
		SnapshotId: snapshot.Id,
		MachineId:  bson.ObjectIdHex(m.Id),
	}

	if err := p.AddSnapshotData(snapshotData); err != nil {
		return nil, err
	}

	tags := []ec2.Tag{
		{Key: "Name", Value: snapshotDesc},
		{Key: "koding-user", Value: m.Username},
		{Key: "koding-machineId", Value: m.Id},
	}

	if _, err := a.Client.CreateTags([]string{snapshot.Id}, tags); err != nil {
		// don't return for a snapshot tag problem
		a.Log.Warning("Failed to tag the new snapshot: %v", err)
	}

	a.Push("Snapshot creation finished successfully", 80, machinestate.Snapshotting)

	// reason why we return nil is, to provide a way for future changes to
	// return an updated IP which is changed once we stop/start a machine.
	// Currently we don't stop the machine (snapshotting works fine without
	// stopping). But if we decide to stop/start the machine, than we need to
	// return an artifact instead of nil
	return nil, nil

}

func (p *Provider) AddSnapshotData(doc *SnapshotDocument) error {
	var account *models.Account
	if err := p.Session.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": doc.username}).One(&account)
	}); err != nil {
		p.Log.Error("Could not fetch account %v: err: %v", doc.username, err)
		return errors.New("could not fetch account from DB")
	}

	// fill remaining fields
	doc.Id = bson.NewObjectId()
	doc.CreatedAt = time.Now().UTC()
	doc.OriginId = account.Id

	err := p.Session.Run(snapshotCollection, func(c *mgo.Collection) error {
		return c.Insert(doc)
	})

	if err != nil {
		p.Log.Error("Could not add snapshot %v: err: %v", doc.MachineId.Hex(), doc, err)
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

func (p *Provider) CheckSnapshotExistence(username, snapshotId string) error {
	var account *models.Account
	if err := p.Session.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
	}); err != nil {
		p.Log.Error("Could not fetch account %v: err: %v", username, err)
		return errors.New("could not fetch account from DB")
	}

	var err error
	var count int

	err = p.Session.Run(snapshotCollection, func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{
			"originId":   account.Id,
			"snapshotId": snapshotId,
		}).Count()
		return err
	})

	if err != nil {
		p.Log.Error("Could not fetch %v: err: %v", snapshotId, err)
		return errors.New("could not check Snapshot existency")
	}

	if count == 0 {
		return errors.New("No snapshot found for the given user")
	}

	return nil
}
