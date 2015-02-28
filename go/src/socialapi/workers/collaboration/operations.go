package collaboration

import (
	socialapimodels "socialapi/models"
	"socialapi/workers/collaboration/models"
	"strconv"
	"strings"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/klient"

	"github.com/koding/bongo"
	"github.com/koding/kite"

	"labix.org/v2/mgo"
)

// DeleteDriveDoc deletes the file from google drive
func (c *Controller) DeleteDriveDoc(ping *models.Ping) error {

	return c.deleteFile(ping.FileId)
}

// EndPrivateMessage stops the collaboration session
func (c *Controller) EndPrivateMessage(ping *models.Ping) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == "" {
		return nil
	}

	id, err := strconv.ParseInt(ping.ChannelId, 10, 64)
	if err != nil {
		return nil
	}

	// fetch the channel
	channel := socialapimodels.NewChannel()
	if err := channel.ById(id); err != nil {
		// if channel is not there, do not do anyting
		if err == bongo.RecordNotFound {
			return nil
		}

		return err
	}

	// delete the channel
	err = channel.Delete()
	if err != nil {
		return err
	}

	ws, err := modelhelper.GetWorkspaceByChannelId(ping.ChannelId)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	// if the workspace is not there, nothing to do
	if err == mgo.ErrNotFound {
		return nil
	}

	return modelhelper.UnsetSocialChannelFromWorkspace(ws.ObjectId)
}

// UnshareVM removes the users from JMachine document
func (c *Controller) UnshareVM(ping *models.Ping) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == "" {
		return nil
	}

	ws, err := modelhelper.GetWorkspaceByChannelId(ping.ChannelId)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	// if the workspace is not there, nothing to do
	if err == mgo.ErrNotFound {
		return nil
	}

	return modelhelper.UnshareMachineByUid(ws.MachineUID)
}

// RemoveUsersFromMachine removes the collaboraters from the host machine
func (c *Controller) RemoveUsersFromMachine(ping *models.Ping) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == "" {
		return nil
	}

	ws, err := modelhelper.GetWorkspaceByChannelId(ping.ChannelId)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	// if the workspace is not there, nothing to do
	if err == mgo.ErrNotFound {
		return nil
	}

	m, err := modelhelper.GetMachineByUid(ws.MachineUID)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	// if the machine is not there, nothing to do
	if err == mgo.ErrNotFound {
		return nil
	}

	// Get the klient.
	klientRef, err := klient.ConnectTimeout(c.kite, m.QueryString, time.Second*10)
	if err != nil {
		if err == klient.ErrDialingFailed || err == kite.ErrNoKitesAvailable {
			c.log.Error(
				"[%s] Klient is not registered to Kontrol. Err: %s",
				m.QueryString,
				err,
			)

			return nil // if the machine is not open, we cant do anything
		}

		return err
	}
	defer klientRef.Close()

	type args struct {
		Username string

		// we are not gonna use this propery here, just for reference
		Permanent bool
	}

	var iterErr error
	for _, user := range m.Users {
		// do not unshare from owner user
		if user.Sudo && user.Owner {
			continue
		}

		// fetch user for its username
		u, err := modelhelper.GetUserById(user.Id.Hex())
		if err != nil {
			c.log.Error(err.Error())

			// if we cant find the regarding user, do not do anything
			if err == mgo.ErrNotFound {
				continue
			}

			iterErr = err

			continue // do not stop iterating, unshare from others
		}

		param := args{
			Username: u.Name,
		}

		_, err = klientRef.Client.Tell("klient.unshare", param)
		if err != nil {
			c.log.Error(err.Error())

			// those are so error prone, force klient side not to change the API
			// or make them exported to some other package?
			if strings.Contains(err.Error(), "user is permanent") {
				continue
			}

			if strings.Contains(err.Error(), "user is not in the shared list") {
				continue
			}

			iterErr = err

			continue // do not stop iterating, unshare from others
		}
	}

	// iterErr will be nil if we dont encounter to any error in iter
	return iterErr

}
