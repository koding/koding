package main

import (
	"net/http"
	"time"
)

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	userInfo, err := fetchUserInfo(w, r)
	if err != nil {
		writeLoggedOutHomeToResp(w)
		return
	}

	onItem := make(chan Item, 0)
	onDone := make(chan bool, 1)
	onError := make(chan error, 1)

	outputter := &Outputter{OnItem: onItem, OnError: onError}

	user := NewLoggedInUser()
	user.Set("Group", kodingGroup)
	user.Set("Username", userInfo.Username)
	user.Set("SessionId", userInfo.ClientId)
	user.Set("Impersonating", userInfo.Impersonating)

	var collectItemCount = 3

	// on new register, there's a race condition where SocialApiId
	// isn't sometimes set; in that case don't prefetch socialdata
	// since it'll return empty
	if !isSocialIdEmpty(userInfo.SocialApiId) {
		collectItemCount = 4
		go fetchSocial(userInfo.SocialApiId, outputter)
	}

	// 3 goroutines below will work in parallel & send results
	go collectItems(user, onItem, onDone, collectItemCount)

	go sendAccount(userInfo.Account, outputter)
	go fetchMachines(userInfo.UserId, outputter)
	go fetchWorkspaces(userInfo.AccountId, outputter)

	// return in 750ms regardless and let client get what it wants
	timeout := time.NewTimer(time.Millisecond * 750)

	select {
	case <-onError:
		writeLoggedOutHomeToResp(w)
	case <-timeout.C:
		writeLoggedInHomeToResp(w, user)
	case <-onDone:
		writeLoggedInHomeToResp(w, user)
	}
}

func collectItems(resp *LoggedInUser, onItem <-chan Item, onDone chan<- bool, max int) {
	for i := 1; i <= max; i++ {
		item := <-onItem
		resp.Set(item.Name, item.Data)
	}

	onDone <- true
}

func isSocialIdEmpty(id string) bool {
	return id == ""
}
