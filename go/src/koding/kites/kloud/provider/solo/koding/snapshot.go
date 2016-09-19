package koding

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/machinestate"
	"strconv"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"golang.org/x/net/context"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
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
	if err := m.Session.AWSClient.DeleteSnapshot(args.SnapshotId); err != nil {
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

	if err := m.Checker.SnapshotTotal(m.ObjectId.Hex(), m.Username); err != nil {
		return err
	}

	a := m.Session.AWSClient

	m.push("Creating snapshot initialized", 10, machinestate.Snapshotting)
	instance, err := a.Instance()
	if err != nil {
		return err
	}

	if len(instance.BlockDeviceMappings) == 0 {
		return fmt.Errorf("createSnapshot: no block device available")
	}

	volumeId := aws.StringValue(instance.BlockDeviceMappings[0].Ebs.VolumeId)
	snapshotDesc := fmt.Sprintf("user-%s-%s", m.Username, m.ObjectId.Hex())

	m.Log.Debug("Creating snapshot '%s'", snapshotDesc)
	m.push("Creating snapshot", 50, machinestate.Snapshotting)
	snapshot, err := a.CreateSnapshot(volumeId, snapshotDesc)
	if err != nil {
		return err
	}
	m.Log.Debug("Snapshot created successfully: %+v", snapshot)

	snapshotData := &models.Snapshot{
		Username:    m.Username,
		Region:      a.Region,
		SnapshotId:  aws.StringValue(snapshot.SnapshotId),
		MachineId:   m.ObjectId,
		StorageSize: strconv.FormatInt(aws.Int64Value(snapshot.VolumeSize), 10),
		Label:       args.Label,
	}

	if err := m.addSnapshotData(snapshotData); err != nil {
		return err
	}

	tags := map[string]string{
		"Name":             snapshotDesc,
		"koding-user":      m.Username,
		"koding-machineId": m.ObjectId.Hex(),
	}

	if err := a.AddTags(aws.StringValue(snapshot.SnapshotId), tags); err != nil {
		// don't return for a snapshot tag problem
		m.Log.Warning("Failed to tag the new snapshot: %v", err)
	}

	m.push("Snapshot creation finished successfully", 80, machinestate.Snapshotting)

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
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

func (m *Machine) checkSnapshotExistence() (bool, error) {
	var account *models.Account
	if err := m.Session.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": m.Username}).One(&account)
	}); err != nil {
		m.Log.Error("Could not fetch account %v: err: %v", m.Username, err)
		return false, errors.New("could not fetch account from DB")
	}

	var err error
	var count int

	meta, err := m.GetMeta()
	if err != nil {
		return false, err
	}

	err = m.Session.DB.Run(snapshotCollection, func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{
			"originId":   account.Id,
			"snapshotId": meta.SnapshotId,
		}).Count()
		return err
	})

	if err != nil {
		m.Log.Error("Could not fetch %v: err: %v", meta.SnapshotId, err)
		return false, errors.New("could not check Snapshot existency")
	}

	return count != 0, nil
}
