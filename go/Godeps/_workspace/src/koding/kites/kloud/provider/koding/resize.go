package koding

import (
	"errors"
	"fmt"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/sshutil"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// Resize increases the current machines underling volume to a larger volume
// without affecting or destroying the users data.
func (m *Machine) Resize(ctx context.Context) (resErr error) {
	// Please read the steps before you dig into the code and try to change or
	// fix something. Intented lines are cleanup or self healing procedures
	// which should be called in a defer - arslan:
	//
	// 0. Check if size is eligible (not equal or less than the current size)
	// 1. Prepare/Get volumeId of current instance
	// 2. Prepare/Get availabilityZone of current instance
	// 3. Stop the instance so we can get the snapshot
	// 4. Create new snapshot from the current volumeId of that stopped instance
	//		4a. Delete snapshot after we are done with all following steps (not needed anymore)
	// 5. Create new volume with the desired size from the snapshot and same zone.
	//		5a. Delete volume if something goes wrong in following steps
	// 6. Detach the volume of current stopped instance.
	//    if something goes wrong:
	//		6a. Detach new volume, attach old volume. New volume will be
	//		    attached in the following step, so we are going to rewind it.
	//	  if everything is ok:
	//		6b. Delete old volume (not needed anymore)
	// 7. Attach new volume to current stopped instance
	// 8. Start the stopped instance with the new larger volume
	// 9. SSH into the machine and run "resize2fs" to sync the storage with the file system
	// 10. Update Default Domain record with the new IP (stopping/starting changes the IP)
	// 11. Update Domain aliases with the new IP (stopping/starting changes the IP)
	// 12. Check if Klient is running

	if err := m.UpdateState("Machine is resizing", machinestate.Pending); err != nil {
		return err
	}

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()
	defer func() {
		if resErr != nil {
			m.UpdateState("Machine is marked as "+latestState.String(), latestState)
		}
	}()

	m.push("Resizing initialized", 10, machinestate.Pending)

	a := m.Session.AWSClient

	m.Log.Info("checking if size is eligible for instance %s", a.Id())
	instance, err := a.Instance()
	if err != nil {
		return err
	}

	if len(instance.BlockDeviceMappings) == 0 {
		return fmt.Errorf("fatal error: no block device available")
	}

	// we need it in a lot of places!
	oldVolumeId := aws.StringValue(instance.BlockDeviceMappings[0].Ebs.VolumeId)

	oldVol, err := a.ExistingVolume(oldVolumeId)
	if err != nil {
		return fmt.Errorf("couldn't retrieve existing volume '%s': %s", oldVolumeId, err)
	}

	currentSize := int(aws.Int64Value(oldVol.Size))

	// reset to current size in DB if something goes wrong, so the user can
	// again apply resize if wished
	revertSize := true
	defer func() {
		if revertSize && resErr != nil {
			if err := m.updateStorageSize(currentSize); err != nil {
				m.Log.Error(err.Error())
			}
		}
	}()

	desiredSize := a.Builder.StorageSize

	m.Log.Debug("DesiredSize: %d, Currentsize %d", desiredSize, currentSize)

	// Storage is counting all current sizes. So we need ask only for the
	// difference that we want to add. So say if the current size is 3
	// and our desired size is 10, we need to ask if we have still
	// limit for a 7 GB space.
	if err := m.Checker.Storage(desiredSize-currentSize, m.Username); err != nil {
		return err
	}

	m.push("Checking if size is eligible", 20, machinestate.Pending)

	m.Log.Info("user wants size '%dGB'. current storage size: '%dGB'", desiredSize, currentSize)
	if desiredSize <= currentSize {
		return fmt.Errorf("resizing is not allowed. Desired size: %dGB should be larger than current size: %dGB",
			desiredSize, currentSize)
	}

	if desiredSize > 100 {
		return fmt.Errorf("resizing is not allowed. Desired size: %d can't be larger than 100GB",
			desiredSize)
	}

	m.push("Stopping old instance", 30, machinestate.Pending)
	m.Log.Info("stopping instance %s", a.Id())
	if m.State() != machinestate.Stopped {
		err := m.Session.AWSClient.Stop(ctx)
		if err != nil {
			return err
		}
	}

	// now we are in a stopped state
	latestState = machinestate.Stopped

	m.push("Creating new snapshot", 40, machinestate.Pending)
	m.Log.Info("creating new snapshot from volume id %s", oldVolumeId)
	snapshotDesc := fmt.Sprintf("Temporary snapshot for instance %s", aws.StringValue(instance.InstanceId))
	snapshot, err := a.CreateSnapshot(oldVolumeId, snapshotDesc)
	if err != nil {
		return err
	}
	newSnapshotId := aws.StringValue(snapshot.SnapshotId)

	defer func() {
		m.Log.Info("deleting snapshot %s (not needed anymore)", newSnapshotId)
		a.DeleteSnapshot(newSnapshotId)
	}()

	m.push("Creating new volume", 50, machinestate.Pending)
	m.Log.Info("creating volume from snapshot id %s with size: %d", newSnapshotId, desiredSize)

	// Go on with the current volume type. SSD(gp2) or Magnetic(standard)
	volType := aws.StringValue(oldVol.VolumeType)
	availZone := aws.StringValue(instance.Placement.AvailabilityZone)

	volume, err := a.CreateVolume(newSnapshotId, availZone, volType, desiredSize)
	if err != nil {
		return err
	}
	newVolumeId := aws.StringValue(volume.VolumeId)
	m.Log.Info("new volume was created with id %s", newVolumeId)

	// delete volume if something goes wrong in following steps
	defer func() {
		if resErr != nil {
			m.Log.Info("(an error occurred) deleting new volume %s ", newVolumeId)
			if err := a.DeleteVolume(newVolumeId); err != nil {
				m.Log.Error(err.Error())
			}
		}
	}()

	m.push("Detaching old volume", 60, machinestate.Pending)
	m.Log.Info("detaching current volume id %s", oldVolumeId)
	if err := a.DetachVolume(oldVolumeId); err != nil {
		return err
	}

	// reattach old volume if something goes wrong, if not delete it
	defer func() {
		// if something goes wrong  detach the newly attached volume and attach
		// back the old volume  so it can be used again
		if resErr != nil {
			m.Log.Info("(an error occurred) detaching newly created volume volume %s ", newVolumeId)
			if err := a.DetachVolume(newVolumeId); err != nil {
				m.Log.Error("couldn't detach: %s", err)
			}

			m.Log.Info("(an error occurred) attaching back old volume %s", oldVolumeId)
			if err = a.AttachVolume(oldVolumeId, a.Id(), "/dev/sda1"); err != nil {
				m.Log.Error("couldn't attach: %s", err)
			}
		} else {
			// if not just delete, it's not used anymore
			m.Log.Info("deleting old volume %s (not needed anymore)", oldVolumeId)
			go a.DeleteVolume(oldVolumeId)
		}
	}()

	m.push("Attaching new volume", 70, machinestate.Pending)
	// attach new volume to current stopped instance
	if err := a.AttachVolume(newVolumeId, a.Id(), "/dev/sda1"); err != nil {
		return err
	}

	// everything is setup, don't revert size anymore if something goes wrong
	revertSize = false

	m.push("Starting instance", 80, machinestate.Pending)
	// start the stopped instance now as we attached the new volume
	instance, err = m.Session.AWSClient.Start(ctx)
	if err != nil {
		return err
	}
	m.IpAddress = aws.StringValue(instance.PublicIpAddress)

	// optionally, we execute resize2fs to reclaim the underlying storage. This
	// needs to be called because for some instances it doesn't get reclaimed
	// and the user ends up having a file system which still reflects the old
	// storage size.
	reclaimSize := func() error {
		keys, ok := publickeys.FromContext(ctx)
		if !ok {
			return errors.New("public keys are not available")
		}

		sshConfig, err := sshutil.SshConfig("root", keys.PrivateKey)
		if err != nil {
			return err
		}

		m.Log.Debug("Connecting to machine with ip '%s' via ssh", m.IpAddress)
		sshClient, err := sshutil.ConnectSSH(m.IpAddress+":22", sshConfig)
		if err != nil {
			return err
		}

		m.Log.Debug("Executing resize2fs command")
		output, err := sshClient.StartCommand("resize2fs /dev/xvda1")
		if err != nil {
			return err
		}

		m.Log.Debug("Resize2fs output:\n%s", output)
		return nil
	}

	// we don't return because this is totally optional. It might that the user
	// alread have the correct size. So it's better to be on the safe side.
	if err := reclaimSize(); err != nil {
		m.Log.Warning("Couldn't reclaim size: %s", err)
	}

	m.push("Updating domain", 85, machinestate.Pending)

	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err)
	}
	if err := m.Session.DNSClient.Upsert(m.Domain, m.IpAddress); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err)
	}

	m.push("Updating domain aliases", 87, machinestate.Pending)
	// also get all domain aliases that belongs to this machine and unset
	domains, err := m.Session.DNSStorage.GetByMachine(m.ObjectId.Hex())
	if err != nil {
		m.Log.Error("fetching domains for unsetting err: %s", err)
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Validate(domain.Name, m.Username); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err)
		}
		if err := m.Session.DNSClient.Upsert(domain.Name, m.IpAddress); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err)
		}
	}

	m.push("Checking remote machine", 90, machinestate.Pending)
	m.Log.Info("connecting to remote Klient instance")
	if !m.isKlientReady() {
		return errors.New("klient is not ready")
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":          m.IpAddress,
				"meta.instanceName":  meta.InstanceName,
				"meta.instanceId":    meta.InstanceId,
				"meta.instance_type": meta.InstanceType,
				"status.state":       machinestate.Running.String(),
				"status.modifiedAt":  time.Now().UTC(),
				"status.reason":      "Machine is running",
			}},
		)
	})
}
