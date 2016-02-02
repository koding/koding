package command

import (
	"strconv"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/sshutil"

	"github.com/koding/kite/protocol"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func CreateUser(opts *UserOptions) (*User, error) {
	username := opts.Username
	groupname := opts.Groupname
	provider := opts.Provider
	template := opts.Template
	machineCount := opts.MachineCount
	label := opts.Label

	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return nil, err
	}

	db := modelhelper.Mongo

	// cleanup old document
	db.Run("jUsers", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"username": username})
	})

	db.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"profile.nickname": username})
	})

	db.Run("jGroups", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"slug": groupname})
	})

	// jAccounts
	accountId := bson.NewObjectId()
	account := &models.Account{
		Id: accountId,
		Profile: models.AccountProfile{
			Nickname: username,
		},
	}

	if err := db.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Insert(&account)
	}); err != nil {
		return nil, err
	}

	// jGroups
	groupId := bson.NewObjectId()
	group := &models.Group{
		Id:    groupId,
		Title: groupname,
		Slug:  groupname,
	}

	if err := db.Run("jGroups", func(c *mgo.Collection) error {
		return c.Insert(&group)
	}); err != nil {
		return nil, err
	}

	// add relation between use and group
	relationship := &models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   accountId,
		TargetName: "JAccount",
		SourceId:   groupId,
		SourceName: "JGroup",
		As:         "member",
	}

	if err := db.Run("relationships", func(c *mgo.Collection) error {
		return c.Insert(&relationship)
	}); err != nil {
		return nil, err
	}

	// jUsers
	userId := bson.NewObjectId()
	user := &models.User{
		ObjectId:      userId,
		Email:         username + "@" + username + ".com",
		LastLoginDate: time.Now().UTC(),
		RegisteredAt:  time.Now().UTC(),
		Name:          username, // bson equivelant is username
		Password:      "somerandomnumbers",
		Status:        "confirmed",
		SshKeys: []struct {
			Title string `bson:"title"`
			Key   string `bson:"key"`
		}{
			{Key: publicKey},
		},
	}

	if err := db.Run("jUsers", func(c *mgo.Collection) error {
		return c.Insert(&user)
	}); err != nil {
		return nil, err
	}

	// jComputeStack and jStackTemplates
	stackTemplateId := bson.NewObjectId()
	stackTemplate := &models.StackTemplate{
		Id: stackTemplateId,
	}
	stackTemplate.Template.Content = template

	if err := db.Run("jStackTemplates", func(c *mgo.Collection) error {
		return c.Insert(&stackTemplate)
	}); err != nil {
		return nil, err
	}

	// later we can add more users with "Owner:false" to test sharing capabilities
	users := []models.MachineUser{
		{Id: userId, Sudo: true, Owner: true},
	}

	machineLabels := make([]string, machineCount)
	machineIds := make([]bson.ObjectId, machineCount)

	for i := 0; i < machineCount; i++ {
		machineLabel := label + strconv.Itoa(i)
		if machineCount == 1 {
			machineLabel = label
		}

		machineId := bson.NewObjectId()
		machine := &models.Machine{
			ObjectId:   machineId,
			Label:      machineLabel,
			Domain:     username + ".dev.koding.io",
			Provider:   provider,
			CreatedAt:  time.Now().UTC(),
			Users:      users,
			Meta:       make(bson.M, 0),
			Groups:     make([]models.MachineGroup, 0),
			Credential: username,
		}

		machine.Assignee.InProgress = false
		machine.Assignee.AssignedAt = time.Now().UTC()
		machine.Status.State = machinestate.NotInitialized.String()
		machine.Status.ModifiedAt = time.Now().UTC()

		machineLabels[i] = machine.Label
		machineIds[i] = machine.ObjectId

		if err := db.Run("jMachines", func(c *mgo.Collection) error {
			return c.Insert(&machine)
		}); err != nil {
			return nil, err
		}
	}

	computeStackID := bson.NewObjectId()
	computeStack := &models.ComputeStack{
		Id:          computeStackID,
		BaseStackId: stackTemplateId,
		Machines:    machineIds,
	}

	if err := db.Run("jComputeStacks", func(c *mgo.Collection) error {
		return c.Insert(&computeStack)
	}); err != nil {
		return nil, err
	}

	cred := &models.Credential{
		Id:         bson.NewObjectId(),
		Provider:   opts.Provider,
		Identifier: bson.NewObjectId().Hex(),
		OriginId:   accountId,
	}

	credData := &models.CredentialData{
		Id:         bson.NewObjectId(),
		Identifier: cred.Identifier,
		OriginId:   accountId,
		Meta: bson.M{
			"queryString": protocol.Kite{ID: opts.KlientID}.String(),
			"memory":      "",
			"box":         "",
			"cpu":         "",
		},
	}

	if err := modelhelper.InsertCredential(cred, credData); err != nil {
		return nil, err
	}

	return &User{
		MachineIDs:      machineIds,
		MachineLabels:   machineLabels,
		StackID:         computeStackID.Hex(),
		StackTemplateID: stackTemplate.Id.Hex(),
		AccountID:       accountId,
		CredID:          cred.Id.Hex(),
		CredDataID:      credData.Id.Hex(),
		PrivateKey:      privateKey,
		PublicKey:       publicKey,
		Identifiers:     []string{cred.Identifier},
	}, nil
}
