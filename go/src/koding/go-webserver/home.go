package main

import (
	"net/http"
	"time"
)

var (
	TimeoutTime = 1500 * time.Millisecond
)

// HomeHandler renders both loggedin and loggedout page for user.
// When user is loggedin, we send some extra data with the payload
// so the client doesn't need to fetch them after the page loads.
func HomeHandler(w http.ResponseWriter, r *http.Request) {
	userInfo, err := fetchUserInfo(w, r)
	if err != nil {
		writeLoggedOutHomeToResp(w)
		return
	}

	onItem := make(chan *Item, 0)    // individual prefetched items come here
	onDone := make(chan struct{}, 1) // signals when done prefetching items
	onError := make(chan error, 1)   // when there's an error, return right away

	collectItemCount := 3
	outputter := &Outputter{OnItem: onItem, OnError: onError}

	// on new register, there's a race condition where SocialApiId
	// isn't sometimes set; in that case don't prefetch socialdata
	// since it'll return empty
	if !isSocialIdEmpty(userInfo.SocialApiId) {
		collectItemCount = 4
		go fetchSocial(userInfo.SocialApiId, outputter)
	}

	user := NewLoggedInUser()
	user.Set("Group", kodingGroup)
	user.Set("Username", userInfo.Username)
	user.Set("SessionId", userInfo.ClientId)
	user.Set("Impersonating", userInfo.Impersonating)

	// the goroutines below (and maybe one above) work in parallel
	// and send items to here to be collected
	go collectItems(user, onItem, onDone, collectItemCount)

	// prefetch items
	go sendAccount(userInfo.Account, outputter) // this is fetched above
	go fetchMachines(userInfo.UserId, outputter)

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
