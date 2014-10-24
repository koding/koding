package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net"
	"net/http"
	"sync"
	"time"

	"labix.org/v2/mgo/bson"
)

func sendAccount(account *models.Account, outputter *Outputter) {
	outputter.OnItem <- &Item{Name: "Account", Data: account}
}

func fetchMachines(userId bson.ObjectId, outputter *Outputter) {
	machines, err := modelhelper.GetMachines(userId)
	if err != nil {
		Log.Error("Couldn't fetch machines: %s", err)
		machines = []*modelhelper.MachineContainer{}
	}

	outputter.OnItem <- &Item{Name: "Machines", Data: machines}
}

func fetchWorkspaces(accountId bson.ObjectId, outputter *Outputter) {
	workspaces, err := modelhelper.GetWorkspaces(accountId)
	if err != nil {
		Log.Error("Couldn't fetch workspaces: %s", err)
		workspaces = []*models.Workspace{}
	}

	outputter.OnItem <- &Item{Name: "Workspaces", Data: workspaces}
}

func fetchSocial(socialApiId string, outputter *Outputter) {
	var wg sync.WaitGroup
	urls := socialUrls(socialApiId)

	onSocialItem := make(chan *Item, len(urls))

	for name, url := range urls {
		go func(name, url string) {
			wg.Add(1)
			defer wg.Done()

			item, err := fetchSocialItem(url)
			if err != nil {
				Log.Error("Fetching prefetched socialdata item: %s, %v", name, err)

				onSocialItem <- &Item{Name: name, Data: nil}
				return
			}

			onSocialItem <- &Item{Name: name, Data: item}
		}(name, url)
	}

	wg.Wait()

	collectSocialItems(onSocialItem, outputter, len(urls))
}

func collectSocialItems(onItem <-chan *Item, outputter *Outputter, max int) {
	socialApiData := map[string]interface{}{}

	for i := 1; i <= max; i++ {
		socialItem := <-onItem

		if socialItem.Data != nil {
			socialApiData[socialItem.Name] = socialItem.Data
		}
	}

	outputter.OnItem <- &Item{Name: "SocialApiData", Data: socialApiData}
}

var timeout = time.Duration(1 * time.Second)

func dialTimeout(network, addr string) (net.Conn, error) {
	return net.DialTimeout(network, addr, timeout)
}

func fetchSocialItem(url string) (interface{}, error) {
	transport := http.Transport{Dial: dialTimeout}
	client := http.Client{Transport: &transport}

	resp, err := client.Get(url)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, errors.New("Socialapi return non 200 status")
	}

	var data interface{}
	decoder := json.NewDecoder(resp.Body)

	err = decoder.Decode(&data)
	if err != nil {
		return nil, err
	}

	return data, nil
}

func socialUrls(id string) map[string]string {
	var urls = map[string]string{
		"followedChannels": buildUrl("%s/account/%[2]s/channels?accountId=%[2]s", id),
		"privateMessages":  buildUrl("%s/privatemessage/list?accountId=%s", id),
		"popularPosts":     buildUrl("%s/popular/posts/public?accountId=%s", id),
		"pinnedMessages":   buildUrl("%s/activity/pin/list?accountId=%s", id),
	}

	return urls
}

func buildUrl(path, socialApiId string) string {
	return fmt.Sprintf(path, conf.SocialApi.ProxyUrl, socialApiId)
}
