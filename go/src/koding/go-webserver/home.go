package main

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"time"
)

var (
	TimeoutTime = 3000 * time.Millisecond
)

func getGroup(r *http.Request) (*models.Group, error) {
	c, err := r.Cookie("groupName")
	if err != nil {
		return nil, err
	}

	if c.Value == "" {
		return nil, errors.New("couldnt find group name")
	}

	// TODO implement caching here
	group, err := modelhelper.GetGroup(c.Value)
	if err != nil {
		return nil, err
	}

	return group, nil
}

// HomeHandler renders both loggedin and loggedout page for user.
// When user is loggedin, we send some extra data with the payload
// so the client doesn't need to fetch them after the page loads.
func HomeHandler(w http.ResponseWriter, r *http.Request) {
	group, err := getGroup(r)
	if err != nil {
		Log.Error("err while getting group %s", err.Error())
		writeLoggedOutHomeToResp(w)
		return
	}

	userInfo, err := prepareUserInfo(w, r, group)
	if err != nil {
		writeLoggedOutHomeToResp(w)
		return
	}

	onItem := make(chan *Item, 0)    // individual prefetched items come here
	onDone := make(chan struct{}, 1) // signals when done prefetching items
	onError := make(chan error, 1)   // when there's an error, return right away

	collectItemCount := 2
	outputter := &Outputter{OnItem: onItem, OnError: onError}

	// on new register, there's a race condition where SocialApiId
	// isn't sometimes set; in that case don't prefetch socialdata
	// since it'll return empty
	if !isSocialIdEmpty(userInfo.SocialApiId) {
		collectItemCount = 3
		go fetchSocial(userInfo, outputter)
	}

	user := NewLoggedInUser()
	user.Set("Group", group)
	user.Set("Username", userInfo.Username)
	user.Set("SessionId", userInfo.ClientId)
	user.Set("Impersonating", userInfo.Impersonating)
	user.Set("UserId", userInfo.UserId)

	// the goroutines below (and maybe one above) work in parallel
	// and send items to here to be collected
	go collectItems(user, onItem, onDone, collectItemCount)

	// prefetch items
	go sendAccount(userInfo.Account, outputter) // this is fetched above
	go fetchEnvData(userInfo, outputter)

	// return if timeout reached and let client get what it wants
	timeout := time.NewTimer(TimeoutTime)

	select {
	case err := <-onError:
		Log.Error("Rendering loggedout page due to error: %v", err)
		writeLoggedOutHomeToResp(w)
	case <-timeout.C:
		Log.Warning("Loggedin page timedout for user: %s", userInfo.Username)
		writeLoggedInHomeToResp(w, user)
	case <-onDone:
		writeLoggedInHomeToResp(w, user)
	}
}

func collectItems(resp *LoggedInUser, onItem <-chan *Item, onDone chan<- struct{}, max int) {
	for i := 1; i <= max; i++ {
		item := <-onItem
		resp.Set(item.Name, item.Data)
	}

	onDone <- struct{}{}
}

func isSocialIdEmpty(id string) bool {
	return id == ""
}
