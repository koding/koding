package main

import (
	"encoding/json"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"sync"

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
	var wg sync.WaitGroup

	var urls = map[string]string{
		"followedChannels": "http://localhost:7000/account/1/channels?accountId=1",
		"privateMessages":  "http://localhost:7000/privatemessage/list?accountId=1",
		"popularposts":     "http://localhost:7000/popular/posts/public?accountId=1",
		"pinnedmessages":   "http://localhost:7000/activity/pin/list?accountId=1",
	}

	onItem := make(chan Item, len(urls))

	for name, url := range urls {
		go func(name, url string) {
			wg.Add(1)
			defer wg.Done()

			item, err := fetchSocialItem(url)
			if err != nil {
				fmt.Println(">>>>>", err)
			}

			onItem <- Item{Name: name, Data: item}
		}(name, url)
	}

	go collectSocialItems(onItem, outputter, len(urls))

	wg.Wait()
}

func collectSocialItems(onItem <-chan Item, outputter *Outputter, max int) {
	socialApiData := map[string]interface{}{}

	for i := 1; i <= max; i++ {
		socialItem := <-onItem

		if socialItem.Data != nil {
			socialApiData[socialItem.Name] = socialItem.Data
		}
	}

	outputter.OnItem <- Item{Name: "SocialApiData", Data: socialApiData}
}

func fetchSocialItem(url string) (interface{}, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	var data interface{}
	decoder := json.NewDecoder(resp.Body)

	err = decoder.Decode(&data)
	if err != nil {
		return nil, err
	}

	return data, nil
}
