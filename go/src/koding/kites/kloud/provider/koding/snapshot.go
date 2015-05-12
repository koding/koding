package koding

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/machinestate"
	"time"

	"github.com/mitchellh/goamz/ec2"
	"golang.org/x/net/context"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	snapshotCollection = "jSnapshots"
)

func (m *Machine) DeleteSnapshot(ctx context.Context) error {
	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not available")
	}

	var args struct {
		SnapshotId string
	}

	if err := req.Args.One().Unmarshal(&args); err != nil {
		return err
	}

	m.Log.Info("deleting snapshot from AWS %s", args.SnapshotId)
	if _, err := m.Session.AWSClient.Client.DeleteSnapshots([]string{args.SnapshotId}); err != nil {
		return err
	}

	m.Log.Debug("deleting snapshot data from MongoDB %s", args.SnapshotId)
	return m.deleteSnapshotData(args.SnapshotId)
}

func (m *Machine) CreateSnapshot(ctx context.Context) (err error) {
	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not available")
	}

	// the user might send us a snapshot label
	var args struct {
		Label string
	}

	err = req.Args.One().Unmarshal(&args)
	if err != nil {
		return err
	}

	if err := m.UpdateState("Machine is creating snapshot", machinestate.Snapshotting); err != nil {
		return err
	}

	latestState := m.State()
	defer func() {
		if err != nil {
			m.UpdateState("Machine is marked as "+latestState.String(), latestState)
		}
	}()

	if err := m.Checker.SnapshotTotal(m.Id.Hex(), m.Username); err != nil {
		return err
	}

	a := m.Session.AWSClient

	m.push("Creating snapshot initialized", 10, machinestate.Snapshotting)
	instance, err := a.Instance()
	if err != nil {
		return err
	}

	if len(instance.BlockDevices) == 0 {
		return fmt.Errorf("createSnapshot: no block device available")
	}

	volumeId := instance.BlockDevices[0].VolumeId
	snapshotDesc := fmt.Sprintf("user-%s-%s", m.Username, m.Id.Hex())

	m.Log.Debug("Creating snapshot '%s'", snapshotDesc)
	m.push("Creating snapshot", 50, machinestate.Snapshotting)
	snapshot, err := a.CreateSnapshot(volumeId, snapshotDesc)
	if err != nil {
		return err
	}
	m.Log.Debug("Snapshot created successfully: %+v", snapshot)

	snapshotData := &models.Snapshot{
		Username:    m.Username,
		Region:      a.Client.Region.Name,
		SnapshotId:  snapshot.Id,
		MachineId:   m.Id,
		StorageSize: snapshot.VolumeSize,
		Label:       args.Label,
	}

	if err := m.addSnapshotData(snapshotData); err != nil {
		return err
	}

	tags := []ec2.Tag{
		{Key: "Name", Value: snapshotDesc},
		{Key: "koding-user", Value: m.Username},
		{Key: "koding-machineId", Value: m.Id.Hex()},
	}

	if _, err := a.Client.CreateTags([]string{snapshot.Id}, tags); err != nil {
		// don't return for a snapshot tag problem
		m.Log.Warning("Failed to tag the new snapshot: %v", err)
	}

	m.push("Snapshot creation finished successfully", 80, machinestate.Snapshotting)

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is running",
			}},
		)
	})
}

func (m *Machine) addSnapshotData(doc *models.Snapshot) error {
	var account *models.Account
	if err := m.Session.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": doc.Username}).One(&account)
	}); err != nil {
		m.Log.Error("Could not fetch account %v: err: %v", doc.Username, err)
		return errors.New("could not fetch account from DB")
	}

	// fill remaining fields
	doc.Id = bson.NewObjectId()
	doc.CreatedAt = time.Now().UTC()
	doc.OriginId = account.Id

	err := m.Session.DB.Run(snapshotCollection, func(c *mgo.Collection) error {
		return c.Insert(doc)
	})

	if err != nil {
		m.Log.Error("Could not add snapshot %v: err: %v", doc.MachineId.Hex(), doc, err)
		return errors.New("could not add snapshot to DB")
	}

	return nil
}

func (m *Machine) deleteSnapshotData(snapshotId string) error {
	err := m.Session.DB.Run(snapshotCollection, func(c *mgo.Collection) error {
		return c.Remove(bson.M{"snapshotId": snapshotId})
	})

	if err != nil {
		m.Log.Error("Could not delete %v: err: %v", snapshotId, err)
		return errors.New("could not delete snapshot from DB")
	}

	return nil
}

func (m *Machine) checkSnapshotExistence() error {
	var account *models.Account
	if err := m.Session.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": m.Username}).One(&account)
	}); err != nil {
		m.Log.Error("Could not fetch account %v: err: %v", m.Username, err)
		return errors.New("could not fetch account from DB")
	}

	var err error
	var count int

	err = m.Session.DB.Run(snapshotCollection, func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{
			"originId":   account.Id,
			"snapshotId": m.Meta.SnapshotId,
		}).Count()
		return err
	})

	if err != nil {
		m.Log.Error("Could not fetch %v: err: %v", m.Meta.SnapshotId, err)
		return errors.New("could not check Snapshot existency")
	}

	if count == 0 {
		return errors.New("No snapshot found for the given user")
	}

	return nil
}
