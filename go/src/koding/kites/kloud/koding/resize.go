package koding

import (
	"fmt"
	"strconv"

	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"github.com/mitchellh/goamz/ec2"
)

// Resizes increases the current machines underling volume to a larger volume
// without affecting the or destroying the users data.
func (p *Provider) Resize(m *protocol.Machine) (resArtifact *protocol.Artifact, resErr error) {
	// Please read the steps before you dig into the code and try to change or
	// fix something. Intented lines are cleanup or self healing procedures
	// which should be called in a defer - arslan:
	//
	// 0. Check if size is eglible (not equal or less than the current size)
	// 1. Prepare/Get volumeId of current instance
	// 2. Prepare/Get availabilityZone of current instance
	// 3. Stop the instance so we can get the snapshot
	// 4. Create new snapshot from the current volumeId of that stopped instance
	//		4a. Delete snapshot after we are done with all following steps (not needed anymore)
	// 5. Create new volume with the desired size from the snapshot and same zone.
	//		5a. Delete volume if something goes wrong in following steps
	// 6. Detach the volume of current stopped instance, if something goes wrong:
	//		6a. Detach new volume, attach old volume. New volume will be
	//		attached in the following step, so we are going to rewind it.
	//	  however if everything is ok:
	//		6b. Delete old volume (not needed anymore)
	// 7. Attach new volume to current stopped instance
	// 8. Start the stopped instance with the new larger volume
	// 9. Update Domain record with the new IP (stopping/starting changes the IP)
	// 10. Check if Klient is running

	infoLog := p.GetInfoLogger(m.Id)

	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	a.Push("Resizing initialized", 10, machinestate.Pending)

	infoLog("checking if size is eglible for instance %s", a.Id())
	instance, err := a.Instance(a.Id())
	if err != nil {
		return nil, err
	}

	if len(instance.BlockDevices) == 0 {
		return nil, fmt.Errorf("fatal error: no block device available")
	}

	// we need in a lot of placages!
	oldVolumeId := instance.BlockDevices[0].VolumeId

	oldVolResp, err := a.Client.Volumes([]string{oldVolumeId}, ec2.NewFilter())
	if err != nil {
		return nil, err
	}

	volSize := oldVolResp.Volumes[0].Size
	currentSize, err := strconv.Atoi(volSize)
	if err != nil {
		return nil, err
	}

	desiredSize := a.Builder.StorageSize

	a.Push("Checking if size is eligible", 20, machinestate.Pending)

	infoLog("user wants size '%dGB'. current storage size: '%dGB'", desiredSize, currentSize)
	if desiredSize <= currentSize {
		return nil, fmt.Errorf("resizing is not allowed. Desired size: %dGB should be larger than current size: %dGB",
			desiredSize, currentSize)
	}

	if 100 < desiredSize {
		return nil, fmt.Errorf("resizing is not allowed. Desired size: %d can't be larger than 100GB",
			desiredSize)
	}

	a.Push("Stopping old instance", 30, machinestate.Pending)
	infoLog("stopping instance %s", a.Id())
	if m.State != machinestate.Stopped {
		err = a.Stop(false)
		if err != nil {
			return nil, err
		}
	}

	a.Push("Creating new snapshot", 40, machinestate.Pending)
	infoLog("creating new snapshot from volume id %s", oldVolumeId)
	snapshotDesc := fmt.Sprintf("Temporary snapshot for instance %s", instance.InstanceId)
	snapshot, err := a.CreateSnapshot(oldVolumeId, snapshotDesc)
	if err != nil {
		return nil, err
	}
	newSnapshotId := snapshot.Id

	defer func() {
		infoLog("deleting snapshot %s (not needed anymore)", newSnapshotId)
		a.DeleteSnapshot(newSnapshotId)
	}()

	a.Push("Creating new volume", 50, machinestate.Pending)
	infoLog("creating volume from snapshot id %s with size: %d", newSnapshotId, desiredSize)
	volume, err := a.CreateVolume(newSnapshotId, instance.AvailZone, desiredSize)
	if err != nil {
		return nil, err
	}
	newVolumeId := volume.VolumeId

	// delete volume if something goes wrong in following steps
	defer func() {
		if resErr != nil {
			infoLog("(an error occured) deleting new volume %s ", newVolumeId)
			_, err := a.Client.DeleteVolume(newVolumeId)
			if err != nil {
				a.Log.Error(err.Error())
			}
		}
	}()

	a.Push("Detaching old volume", 60, machinestate.Pending)
	infoLog("detaching current volume id %s", oldVolumeId)
	if err := a.DetachVolume(oldVolumeId); err != nil {
		return nil, err
	}

	// reattach old volume if something goes wrong, if not delete it
	defer func() {
		// if something goes wrong  detach the newly attached volume and attach
		// back the old volume  so it can be used again
		if resErr != nil {
			infoLog("(an error occured) detaching newly created volume volume %s ", newVolumeId)
			_, err := a.Client.DetachVolume(newVolumeId)
			if err != nil {
				a.Log.Error(err.Error())
			}

			infoLog("(an error occured) attaching back old volume %s", oldVolumeId)
			_, err = a.Client.AttachVolume(oldVolumeId, a.Id(), "/dev/sda1")
			if err != nil {
				a.Log.Error(err.Error())
			}
		} else {
			// if not just delete, it's not used anymore
			infoLog("deleting old volume %s (not needed anymore)", oldVolumeId)
			go a.Client.DeleteVolume(oldVolumeId)
		}
	}()

	a.Push("Attaching new volume", 70, machinestate.Pending)
	// attach new volume to current stopped instance
	if err := a.AttachVolume(newVolumeId, a.Id(), "/dev/sda1"); err != nil {
		return nil, err
	}

	a.Push("Starting instance", 80, machinestate.Pending)
	// start the stopped instance now as we attached the new volume
	artifact, err := a.Start(false)
	if err != nil {
		return nil, err
	}

	a.Push("Updating domain", 85, machinestate.Pending)
	// update Domain record with the new IP
	if err := p.UpdateDomain(artifact.IpAddress, m.Domain.Name, m.Username); err != nil {
		return nil, err
	}

	infoLog("updating user domain tag %s of instance %s", m.Domain.Name, artifact.InstanceId)
	if err := a.AddTag(artifact.InstanceId, "koding-domain", m.Domain.Name); err != nil {
		return nil, err
	}

	a.Push("Checking connectivity", 90, machinestate.Pending)
	artifact.DomainName = m.Domain.Name

	infoLog("connecting to remote Klient instance")
	if p.IsKlientReady(m.QueryString) {
		p.Log.Info("[%s] klient is ready.", m.Id)
	} else {
		p.Log.Warning("[%s] klient is not ready. I couldn't connect to it.", m.Id)
	}

	return artifact, nil
}
