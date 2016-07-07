package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
	"net"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"strings"
	"sync"
	"time"
)

const IntegrationProxyURL = "/api/integration"

func fetchSocial(userInfo *UserInfo, user *LoggedInUser, wg *sync.WaitGroup) {
	defer wg.Done()
	// on new register, there's a race condition where SocialApiId
	// isn't sometimes set; in that case don't prefetch socialdata
	// since it'll return empty
	if userInfo.SocialApiId == "" {
		return
	}

	showExempt := "false"
	// show troll content if only user is admin or requester is marked as troll
	if userInfo.Account != nil &&
		(userInfo.Account.HasFlag(models.SUPER_ADMIN_FLAG) || userInfo.Account.IsExempt) {
		showExempt = "true"
	}

	var socialWg sync.WaitGroup
	urls := socialUrls(userInfo, "showExempt="+showExempt)

	onSocialItem := make(chan *Item, len(urls))

	for name, url := range urls {
		socialWg.Add(1)
		go func(name, url string) {
			defer socialWg.Done()

			item, err := fetchSocialItem(url, userInfo)
			if err != nil {
				Log.Error("Fetching prefetched socialdata item: %s, %v", name, err)
			}

			onSocialItem <- &Item{Name: name, Data: item}
		}(name, url)
	}

	socialWg.Wait()

	socialApiData := collectSocialItems(onSocialItem, len(urls))
	user.Set("SocialApiData", socialApiData)
}

func collectSocialItems(onItem <-chan *Item, max int) map[string]interface{} {
	socialApiData := map[string]interface{}{}

	for i := 1; i <= max; i++ {
		socialItem := <-onItem

		if socialItem.Data != nil {
			socialApiData[socialItem.Name] = socialItem.Data
		}
	}

	return socialApiData
}

var timeout = time.Duration(1 * time.Second)

func dialTimeout(network, addr string) (net.Conn, error) {
	return net.DialTimeout(network, addr, timeout)
}

func fetchSocialItem(fetchURL string, userInfo *UserInfo) (interface{}, error) {
	transport := http.Transport{Dial: dialTimeout}
	client := http.Client{Transport: &transport}
	jar, err := cookiejar.New(nil)
	if err != nil {
		return nil, err
	}

	u, err := url.Parse(conf.SocialApi.CustomDomain.Local)
	if err != nil {
		return nil, err
	}

	jar.SetCookies(u, userInfo.Cookies)
	client.Jar = jar

	resp, err := client.Get(fetchURL)
	defer func() {
		if resp != nil {
			resp.Body.Close()
		}
	}()

	if err != nil {
		return nil, err
	}

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

func socialUrls(userInfo *UserInfo, extras ...string) map[string]string {
	id := userInfo.SocialApiId
	groupQuery := fmt.Sprintf("groupName=%s", userInfo.Group.Slug)
	extras = append(extras, groupQuery)

	var urls = map[string]string{
		"followedChannels": buildUrl("%s/account/%[2]s/channels?accountId=%[2]s", id, extras...),
		"privateMessages":  buildUrl("%s/privatechannel/list?accountId=%s", id, extras...),
		"popularPosts":     buildUrl("%s/popular/posts/public?accountId=%s", id, extras...),
		"bot":              fmt.Sprintf("%s%s/botchannel", conf.SocialApi.CustomDomain.Local, IntegrationProxyURL),
		// "pinnedMessages":   buildUrl("%s/activity/pin/list?accountId=%s", id, extras...),
	}

	return urls
}

func buildUrl(path, socialApiId string, extras ...string) string {
	return fmt.Sprintf(path, conf.SocialApi.ProxyUrl, socialApiId) + "&" + strings.Join(extras, "&")
}
