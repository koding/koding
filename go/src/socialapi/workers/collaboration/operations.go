package collaboration

import (
	mongomodels "koding/db/models"
	socialapimodels "socialapi/models"
	"socialapi/workers/collaboration/models"
	"strconv"
	"strings"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/klient"

	"socialapi/request"

	"github.com/koding/bongo"
	"github.com/koding/kite"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// DeleteDriveDoc deletes the file from google drive
func (c *Controller) DeleteDriveDoc(ping *models.Ping) error {
	// if file id is nil, there is nothing to do
	if ping.FileId == "" {
		return nil
	}

	return c.deleteFile(ping.FileId)
}

// EndPrivateMessage stops the collaboration session and deletes the all
// messages from db
func (c *Controller) EndPrivateMessage(ping *models.Ping) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == 0 {
		return nil
	}

	// fetch the channel
	channel := socialapimodels.NewChannel()
	if err := channel.ById(ping.ChannelId); err != nil {
		// if channel is not there, do not do anyting
		if err == bongo.RecordNotFound {
			return nil
		}

		return err
	}

	canOpen, err := channel.CanOpen(ping.AccountId)
	if err != nil {
		return err
	}

	if !canOpen {
		return nil // if the requester can not open the channel do not process
	}

	// delete the channel
	err = channel.Delete()
	if err != nil {
		return err
	}

	ws, err := modelhelper.GetWorkspaceByChannelId(
		strconv.FormatInt(ping.ChannelId, 10),
	)
	if err != nil {
		return filterErr(err)
	}

	return modelhelper.UnsetSocialChannelFromWorkspace(ws.ObjectId)
}

// UnshareVM removes the users from JMachine document
func (c *Controller) UnshareVM(ping *models.Ping, toBeRemovedUsers []bson.ObjectId) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == 0 {
		return nil
	}

	ws, err := modelhelper.GetWorkspaceByChannelId(
		strconv.FormatInt(ping.ChannelId, 10),
	)
	if err != nil {
		return filterErr(err)
	}

	if len(toBeRemovedUsers) == 0 {
		return nil // no one to remove
	}

	return modelhelper.RemoveUsersFromMachineByIds(ws.MachineUID, toBeRemovedUsers)
}

func (c *Controller) findToBeRemovedUsers(ping *models.Ping) ([]bson.ObjectId, error) {
	ws, err := modelhelper.GetWorkspaceByChannelId(
		strconv.FormatInt(ping.ChannelId, 10),
	)
	if err != nil {
		return nil, filterErr(err)
	}

	machine, err := modelhelper.GetMachineByUid(ws.MachineUID)
	if err != nil {
		return nil, filterErr(err)
	}

	ownerMachineUser := machine.Owner()
	if ownerMachineUser == nil {
		c.log.Critical("owner couldnt found %+v", ping)
		return nil, nil // if we cant find the owner, we cant process the users
	}

	ownerAccount, err := modelhelper.GetAccountByUserId(ownerMachineUser.Id)
	if err != nil {
		return nil, filterErr(err)
	}

	//	get workspaces of the owner
	ownersWorkspaces, err := modelhelper.GetWorkspaces(ownerAccount.Id)
	if err != nil {
		return nil, filterErr(err)
	}

	users := partitionUsers(ownerAccount, ownersWorkspaces, ws)

	var toBeRemovedUsers []bson.ObjectId
	for accountID, count := range users {
		// if we count the user more than once, that means user is in another
		// workspace too
		if count > 1 {
			continue
		}

		u, err := modelhelper.GetUserByAccountId(accountID)
		if err != nil {
			return nil, err
		}

		toBeRemovedUsers = append(toBeRemovedUsers, u.ObjectId)
	}

	var filteredUsers []bson.ObjectId
	permanentUsers := make(map[string]struct{})
	for _, user := range machine.Users {
		if user.Permanent {
			permanentUsers[user.Id.Hex()] = struct{}{}
		}
	}

	for _, toBeRemovedUser := range toBeRemovedUsers {
		if _, ok := permanentUsers[toBeRemovedUser.Hex()]; !ok {
			filteredUsers = append(filteredUsers, toBeRemovedUser)
		}
	}

	return filteredUsers, nil
}

// filterErr filters unwanted errors, this is useful on which cases we should
// retry the operation.
func filterErr(err error) error {
	if err == mgo.ErrNotFound { // do not retry on mongo not found
		return nil
	}

	return err
}

func partitionUsers(ownerAccount *mongomodels.Account, ownersWorkspaces []*mongomodels.Workspace, ws *mongomodels.Workspace) map[string]int {
	users := make(map[string]int)
	for _, ownerWS := range ownersWorkspaces {
		// if the workspace belongs to other vm, skip
		if ownerWS.MachineUID != ws.MachineUID {
			continue
		}

		channelID, err := strconv.ParseInt(ownerWS.ChannelId, 10, 64)
		if err != nil {
			continue
		}

		channel := socialapimodels.NewChannel()
		channel.Id = channelID
		participants, err := channel.FetchParticipants(&request.Query{})
		if err != nil {
			return nil
		}

		// fetch the channels of the workspaces
		for _, participant := range participants {
			// skip the owner
			if participant.OldId == ownerAccount.Id.Hex() {
				continue
			}

			if _, ok := users[participant.OldId]; !ok {
				users[participant.OldId] = 0
			}
			users[participant.OldId] = users[participant.OldId] + 1
		}
	}

	return users
}

// RemoveUsersFromMachine removes the collaboraters from the host machine
func (c *Controller) RemoveUsersFromMachine(ping *models.Ping, toBeRemovedUsers []bson.ObjectId) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == 0 {
		return nil
	}

	ws, err := modelhelper.GetWorkspaceByChannelId(strconv.FormatInt(ping.ChannelId, 10))
	if err != nil {
		return filterErr(err)
	}

	m, err := modelhelper.GetMachineByUid(ws.MachineUID)
	if err != nil {
		return filterErr(err)
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
		// Permanent bool
	}

	var iterErr error

	for _, toBeDeletedUser := range toBeRemovedUsers {

		// fetch user for its username
		u, err := modelhelper.GetUserById(toBeDeletedUser.Hex())
		if err != nil {
			c.log.Error("couldnt get user", err.Error())

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
			c.log.Error("couldnt unshare %+v", err.Error())

			// those are so error prone, force klient side not to change the API
			// or make them exported to some other package?
			if strings.Contains(err.Error(), "user is permanent") {
				continue
			}

			if strings.Contains(err.Error(), "user is not in the shared list") {
				continue
			}

			if strings.Contains(err.Error(), "User not found") {
				continue
			}

			iterErr = err

			continue // do not stop iterating, unshare from others
		}
	}

	res, err := klientRef.Client.Tell("klient.shared", nil)
	if err == nil {
		c.log.Info("other users in the machine: %+v", res.MustString())
	}

	// iterErr will be nil if we dont encounter to any error in iter
	return iterErr

}
