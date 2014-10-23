package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo/bson"
)

func sendAccount(account *models.Account, outputter *Outputter) {
	outputter.OnItem <- Item{Name: "Account", Data: account}
}

func fetchMachines(userId bson.ObjectId, outputter *Outputter) {
	machines, err := modelhelper.GetMachines(userId)
	if err != nil {
		Log.Error("Couldn't fetch machines: %s", err)
		machines = []*modelhelper.MachineContainer{}
	}

	outputter.OnItem <- Item{Name: "Machines", Data: machines}
}

func fetchWorkspaces(accountId bson.ObjectId, outputter *Outputter) {
	workspaces, err := modelhelper.GetWorkspaces(accountId)
	if err != nil {
		Log.Error("Couldn't fetch workspaces: %s", err)
		workspaces = []*models.Workspace{}
	}

	outputter.OnItem <- Item{Name: "Workspaces", Data: workspaces}
}

func fetchSocial(accountId bson.ObjectId, outputter *Outputter) {
	outputter.OnItem <- Item{Name: "SocialApiData", Data: nil}
}
