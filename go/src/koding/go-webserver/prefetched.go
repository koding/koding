package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net"
	"net/http"
	"strings"
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

func fetchSocial(userInfo *UserInfo, outputter *Outputter) {
	socialApiId := userInfo.SocialApiId

	showExempt := "false"
	// show troll content if only user is admin or requester is marked as troll
	if userInfo.Account != nil &&
		(userInfo.Account.HasFlag(models.SUPER_ADMIN_FLAG) || userInfo.Account.IsExempt) {
		showExempt = "true"
	}

	var wg sync.WaitGroup
	urls := socialUrls(socialApiId, "showExempt="+showExempt)

	onSocialItem := make(chan *Item, len(urls))

	for name, url := range urls {
		wg.Add(1)
		go func(name, url string) {
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

func socialUrls(id string, extras ...string) map[string]string {
	var urls = map[string]string{
		"followedChannels": buildUrl("%s/account/%[2]s/channels?accountId=%[2]s", id, extras...),
		"privateMessages":  buildUrl("%s/privatemessage/list?accountId=%s", id, extras...),
		"popularPosts":     buildUrl("%s/popular/posts/public?accountId=%s", id, extras...),
		"pinnedMessages":   buildUrl("%s/activity/pin/list?accountId=%s", id, extras...),
	}

	return urls
}

func buildUrl(path, socialApiId string, extras ...string) string {
	return fmt.Sprintf(path, conf.SocialApi.ProxyUrl, socialApiId) + "&" + strings.Join(extras, "&")
}
